from sqlalchemy import func, select
from sqlalchemy.orm import Session


def next_position(db: Session, column) -> int:
    current = db.scalar(select(func.max(column)))
    return (current if current is not None else -1) + 1


def apply_order(items_by_id: dict, ids: list[int], attr: str = "sort_order") -> None:
    """Assign positions 0..n in the order of ``ids``; unknown ids are ignored,
    items not mentioned keep their relative order after the listed ones."""
    position = 0
    seen: set[int] = set()
    for item_id in ids:
        item = items_by_id.get(item_id)
        if item is not None and item_id not in seen:
            setattr(item, attr, position)
            seen.add(item_id)
            position += 1
    rest = sorted((i for k, i in items_by_id.items() if k not in seen), key=lambda i: getattr(i, attr))
    for item in rest:
        setattr(item, attr, position)
        position += 1
