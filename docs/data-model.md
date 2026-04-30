# Data model

Single farm, so there is no tenancy scoping. All documents live at the
root of Firestore under the following collections.

## Collections

### `users/{uid}`

One document per authenticated user, created by a manager when they
provision a worker account. `uid` matches the Firebase Auth UID.

| Field         | Type                                | Notes                              |
|---------------|-------------------------------------|------------------------------------|
| `email`       | string                              | lowercased                         |
| `displayName` | string                              |                                    |
| `role`        | `"manager"` \| `"worker"`           | drives Firestore rules             |
| `active`      | bool                                | `true`; set to `false` to revoke access |
| `fcmTokens`   | array\<string\>                     | device tokens for push (future)    |

### `crops/{cropId}`

The master list of things the farm grows. Managed from the Windows UI.

| Field         | Type                                    | Notes                  |
|---------------|-----------------------------------------|------------------------|
| `name`        | string                                  |                        |
| `defaultUnit` | `"units"` \| `"kg"` \| `"boxes"`        |                        |
| `active`      | bool                                    | hide from picker when false |

### `pickingLists/{listId}`

| Field         | Type                                    | Notes                                  |
|---------------|-----------------------------------------|----------------------------------------|
| `name`        | string                                  | e.g. "Thursday morning pick"           |
| `scheduledAt` | timestamp                               |                                        |
| `status`      | `"draft"` \| `"published"` \| `"completed"` | workers only see `published`       |
| `createdBy`   | string (uid)                            |                                        |
| `updatedAt`   | timestamp                               | server timestamp on every write        |

#### `pickingLists/{listId}/items/{itemId}` (subcollection)

| Field            | Type                                | Notes                                     |
|------------------|-------------------------------------|-------------------------------------------|
| `cropId`         | string                              | foreign key to `crops/`                   |
| `cropName`       | string                              | denormalized for list rendering           |
| `quantity`       | number                              | planned quantity                          |
| `unit`           | `"units"` \| `"kg"` \| `"boxes"`    |                                           |
| `note`           | string?                             | optional                                  |
| `assignedTo`     | string? (uid)                       | null = unassigned                         |
| `pickedQuantity` | number?                             | null until marked picked                  |
| `pickedAt`       | timestamp?                          |                                           |
| `completedBy`    | string? (uid)                       | who marked picked                         |

The **difference** (`pickedQuantity - quantity`) is a client-side
derived field, not stored.

### `templates/{templateId}`

Saved named lists the manager can reuse (Windows-only feature).

| Field    | Type                                    | Notes                      |
|----------|-----------------------------------------|----------------------------|
| `name`   | string                                  | e.g. "Thursday pick"       |
| `items`  | array\<map\>                            | same shape as `items/` minus `assignedTo`, `picked*` |

## Security rules — design

See `firebase/firestore.rules`. The goals:

1. Workers can't modify `pickingLists/*` or `pickingLists/*/items/*`
   beyond claiming a row and marking it picked.
2. Workers can claim only unassigned rows. Reassigning belongs to the
   row's current owner or a manager.
3. Managers can do everything.
4. Every signed-in user can read the user directory and the crops
   catalog (workers need both to render the list).

The worker-write path allows exactly this diff set:
`{assignedTo, pickedQuantity, pickedAt, completedBy}`. Other fields
stay immutable under the worker's pen.

## Indexes

Composite indexes in `firebase/firestore.indexes.json`:

- `pickingLists` by `(status asc, scheduledAt desc)` — the "today's
  lists, newest first" query on the home screen.
- `items` by `(assignedTo asc, cropName asc)` — the "my rows" filter.

## Denormalization choices

- `cropName` is copied onto each item so we can render a picking list
  without a second fetch per row. If a crop is renamed, existing items
  keep the old name — a manager "touch up" action can backfill.
- `role` lives on `users/{uid}` and is read on every rule evaluation
  via `get()`. Acceptable for a single-farm deployment (low doc
  count); reconsider if we ever shard by farm.
