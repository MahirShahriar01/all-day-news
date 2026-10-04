import {
  DndContext, KeyboardSensor, PointerSensor, closestCenter, useSensor, useSensors, type DragEndEvent,
} from "@dnd-kit/core";
import {
  SortableContext, arrayMove, sortableKeyboardCoordinates, useSortable, verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import type { ReactNode } from "react";

/**
 * Drag-and-drop list. Works with mouse, touch and keyboard
 * (focus the ⠿ handle, press Space, move with arrow keys, Space to drop).
 */
export function SortableList<T extends { id: number }>({ items, onReorder, render, disabled }: {
  items: T[];
  onReorder: (items: T[]) => void;
  render: (item: T, handle: ReactNode) => ReactNode;
  disabled?: boolean;
}) {
  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 4 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates }),
  );
  const onDragEnd = ({ active, over }: DragEndEvent) => {
    if (!over || active.id === over.id) return;
    const from = items.findIndex((i) => i.id === active.id);
    const to = items.findIndex((i) => i.id === over.id);
    onReorder(arrayMove(items, from, to));
  };
  return (
    <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={onDragEnd}>
      <SortableContext items={items.map((i) => i.id)} strategy={verticalListSortingStrategy}>
        <div className="list">
          {items.map((item) => (
            <SortableItem key={item.id} id={item.id} disabled={disabled}>
              {(handle) => render(item, handle)}
            </SortableItem>
          ))}
        </div>
      </SortableContext>
    </DndContext>
  );
}

function SortableItem({ id, children, disabled }: { id: number; children: (handle: ReactNode) => ReactNode; disabled?: boolean }) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({ id, disabled });
  const style = { transform: CSS.Transform.toString(transform), transition };
  const handle = disabled ? null : (
    <button className="handle" aria-label="Drag to reorder" title="Drag to reorder" {...attributes} {...listeners}>⠿</button>
  );
  return (
    <div ref={setNodeRef} style={style} className={isDragging ? "dragging-wrap" : ""} data-dragging={isDragging}>
      {children(handle)}
    </div>
  );
}
