import type { ReactNode } from 'react';

export interface Column<T> {
  key: string;
  header: string;
  render?: (item: T) => ReactNode;
}

interface DataTableProps<T> {
  data: T[];
  columns: Column<T>[];
  onRowClick?: (item: T) => void;
  emptyMessage?: string;
}

export default function DataTable<T>({
  data,
  columns,
  onRowClick,
  emptyMessage = 'No data',
}: DataTableProps<T>) {
  if (data.length === 0) {
    return <div className="text-sm text-slate-500 py-8 text-center">{emptyMessage}</div>;
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-slate-200">
            {columns.map((col) => (
              <th
                key={col.key}
                className="text-left py-3 px-4 font-medium text-slate-600"
              >
                {col.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100">
          {data.map((item, i) => (
            <tr
              key={i}
              onClick={() => onRowClick?.(item)}
              className={onRowClick ? 'hover:bg-slate-50 cursor-pointer' : ''}
            >
              {columns.map((col) => (
                <td key={col.key} className="py-3 px-4 text-slate-700">
                  {col.render
                    ? col.render(item)
                    : String((item as Record<string, unknown>)[col.key] ?? '')}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
