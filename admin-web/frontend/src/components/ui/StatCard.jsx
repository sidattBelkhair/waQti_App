export default function StatCard({ title, value, icon: Icon, color = 'blue', trend }) {
  const colors = { blue: 'bg-blue-50 text-blue-600', green: 'bg-green-50 text-green-600', orange: 'bg-orange-50 text-orange-600', red: 'bg-red-50 text-red-600', purple: 'bg-purple-50 text-purple-600' };
  return (
    <div className="bg-white rounded-xl border border-slate-200 p-6 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm text-slate-500">{title}</p>
          <p className="text-3xl font-bold mt-1 text-slate-800">{value}</p>
          {trend && <p className={`text-sm mt-1 ${trend > 0 ? 'text-green-600' : 'text-red-600'}`}>{trend > 0 ? '+' : ''}{trend}%</p>}
        </div>
        {Icon && <div className={`w-12 h-12 rounded-lg flex items-center justify-center ${colors[color]}`}><Icon size={24} /></div>}
      </div>
    </div>
  );
}
