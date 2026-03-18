export default function DataTable({ columns, data, onRowClick }) {
  return (
    <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
      <table className="w-full">
        <thead className="bg-slate-50 border-b border-slate-200">
          <tr>{columns.map(col => <th key={col.key} className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase">{col.label}</th>)}</tr>
        </thead>
        <tbody className="divide-y divide-slate-100">
          {data.length === 0 ? (
            <tr><td colSpan={columns.length} className="px-6 py-12 text-center text-slate-400">Aucune donnee</td></tr>
          ) : data.map((row, i) => (
            <tr key={row._id || i} onClick={() => onRowClick?.(row)} className={`hover:bg-slate-50 ${onRowClick ? 'cursor-pointer' : ''}`}>
              {columns.map(col => <td key={col.key} className="px-6 py-4 text-sm text-slate-700">{col.render ? col.render(row) : row[col.key]}</td>)}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
