// Equivalent mobile de DataTable : une carte empilée par ligne, en réutilisant
// la même config `columns` (label + render) pour ne pas dupliquer la logique
// d'affichage entre desktop et mobile.
export default function MobileCardList({ columns, data, onRowClick, primaryKey }) {
  const primary = columns.find(c => c.key === primaryKey) || columns[0];
  const rest = columns.filter(c => c.key !== primary.key);

  if (data.length === 0) {
    return <div className="bg-white rounded-xl border border-slate-200 p-6 text-center text-slate-400">Aucune donnee</div>;
  }

  return (
    <div className="space-y-3">
      {data.map((row, i) => (
        <div key={row._id || i} onClick={() => onRowClick?.(row)}
          className={`bg-white rounded-xl border border-slate-200 p-4 ${onRowClick ? 'cursor-pointer active:bg-slate-50' : ''}`}>
          <div>{primary.render ? primary.render(row) : row[primary.key]}</div>
          <div className="mt-3 pt-3 border-t border-slate-100 space-y-2">
            {rest.map(col => (
              <div key={col.key} className="flex items-center justify-between gap-3 text-sm">
                <span className="text-slate-400 text-xs font-medium uppercase tracking-wide shrink-0">{col.label}</span>
                <span className="text-slate-700 text-right">{col.render ? col.render(row) : row[col.key]}</span>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}
