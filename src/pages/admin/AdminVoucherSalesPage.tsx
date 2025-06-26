import React, { useState, useEffect } from 'react';
import AdminLayout from '../../components/admin/AdminLayout';
import { Download, Calendar, Filter, TrendingUp, DollarSign, ShoppingCart, Users, CheckCircle, XCircle, Copy } from 'lucide-react';
import { getVoucherSales, toggleVoucherFulfillment } from '../../lib/voucher';

interface VoucherSale {
  id: string;
  purchaser_name: string;
  purchaser_email: string;
  voucher_code: string;
  amount: number;
  currency: string;
  payment_intent_id: string | null;
  fulfilled: boolean;
  created_at: string;
}

interface SalesMetrics {
  totalSales: number;
  totalRevenue: number;
  averageOrderValue: number;
  conversionRate: number;
}

const AdminVoucherSalesPage: React.FC = () => {
  const [sales, setSales] = useState<VoucherSale[]>([]);
  const [filteredSales, setFilteredSales] = useState<VoucherSale[]>([]);
  const [metrics, setMetrics] = useState<SalesMetrics>({
    totalSales: 0,
    totalRevenue: 0,
    averageOrderValue: 0,
    conversionRate: 0
  });
  const [dateRange, setDateRange] = useState({
    from: '',
    to: ''
  });
  const [statusFilter, setStatusFilter] = useState('all');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchVoucherSales();
  }, []);

  useEffect(() => {
    filterSales();
    calculateMetrics();
  }, [sales, dateRange, statusFilter]);

  const fetchVoucherSales = async () => {
    try {
      setLoading(true);
      const data = await getVoucherSales();
      setSales(data);
    } catch (err) {
      console.error('Error fetching voucher sales:', err);
      setError('Failed to load voucher sales. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const filterSales = () => {
    let filtered = [...sales];
    
    if (dateRange.from && dateRange.to) {
      filtered = filtered.filter(sale => {
        const saleDate = new Date(sale.created_at);
        const fromDate = new Date(dateRange.from);
        const toDate = new Date(dateRange.to);
        return saleDate >= fromDate && saleDate <= toDate;
      });
    }
    
    if (statusFilter !== 'all') {
      const fulfilled = statusFilter === 'fulfilled';
      filtered = filtered.filter(sale => sale.fulfilled === fulfilled);
    }
    
    setFilteredSales(filtered);
  };

  const calculateMetrics = () => {
    const totalSales = filteredSales.length;
    const totalRevenue = filteredSales.reduce((sum, sale) => sum + sale.amount, 0);
    const averageOrderValue = totalSales > 0 ? totalRevenue / totalSales : 0;
    const conversionRate = sales.length > 0 ? (totalSales / sales.length) * 100 : 0;

    setMetrics({
      totalSales,
      totalRevenue,
      averageOrderValue,
      conversionRate
    });
  };

  const handleToggleFulfillment = async (id: string, currentStatus: boolean) => {
    try {
      await toggleVoucherFulfillment(id, !currentStatus);
      
      // Update local state
      setSales(prevSales => prevSales.map(sale => 
        sale.id === id 
          ? { ...sale, fulfilled: !currentStatus } 
          : sale
      ));
    } catch (err) {
      console.error('Error updating voucher fulfillment:', err);
      setError('Failed to update voucher status. Please try again.');
    }
  };

  const copyVoucherCode = (code: string) => {
    navigator.clipboard.writeText(code);
    alert(`Voucher code ${code} copied to clipboard!`);
  };

  const exportToCSV = () => {
    const headers = ['Date', 'Purchaser', 'Email', 'Voucher Code', 'Amount', 'Fulfilled'];
    const csvContent = [
      headers.join(','),
      ...filteredSales.map(sale => [
        new Date(sale.created_at).toLocaleDateString(),
        sale.purchaser_name,
        sale.purchaser_email,
        sale.voucher_code,
        sale.amount,
        sale.fulfilled ? 'Yes' : 'No'
      ].join(','))
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `voucher-sales-${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
    window.URL.revokeObjectURL(url);
  };

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-gray-900">Online Voucher Sales</h1>
            <p className="text-gray-600">Track and manage online voucher sales</p>
          </div>
          <button
            onClick={exportToCSV}
            className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg flex items-center"
          >
            <Download size={20} className="mr-2" />
            Export CSV
          </button>
        </div>

        {/* Metrics Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className="p-2 bg-blue-100 rounded-lg">
                <ShoppingCart className="h-6 w-6 text-blue-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">Total Sales</p>
                <p className="text-2xl font-semibold text-gray-900">{metrics.totalSales}</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className="p-2 bg-green-100 rounded-lg">
                <DollarSign className="h-6 w-6 text-green-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">Total Revenue</p>
                <p className="text-2xl font-semibold text-gray-900">€{metrics.totalRevenue.toFixed(2)}</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className="p-2 bg-purple-100 rounded-lg">
                <TrendingUp className="h-6 w-6 text-purple-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">Avg Order Value</p>
                <p className="text-2xl font-semibold text-gray-900">€{metrics.averageOrderValue.toFixed(2)}</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className="p-2 bg-orange-100 rounded-lg">
                <Users className="h-6 w-6 text-orange-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">Conversion Rate</p>
                <p className="text-2xl font-semibold text-gray-900">{metrics.conversionRate.toFixed(1)}%</p>
              </div>
            </div>
          </div>
        </div>

        {/* Filters */}
        <div className="bg-white rounded-lg shadow p-6">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">From Date</label>
              <input
                type="date"
                value={dateRange.from}
                onChange={(e) => setDateRange(prev => ({ ...prev, from: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">To Date</label>
              <input
                type="date"
                value={dateRange.to}
                onChange={(e) => setDateRange(prev => ({ ...prev, to: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Status</label>
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
              >
                <option value="all">All Statuses</option>
                <option value="fulfilled">Fulfilled</option>
                <option value="unfulfilled">Unfulfilled</option>
              </select>
            </div>

            <div className="flex items-end">
              <button 
                onClick={() => {
                  setDateRange({ from: '', to: '' });
                  setStatusFilter('all');
                }}
                className="w-full flex items-center justify-center px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                <Filter size={20} className="mr-2" />
                Reset Filters
              </button>
            </div>
          </div>
        </div>

        {/* Sales Table */}
        <div className="bg-white rounded-lg shadow overflow-hidden">
          {loading ? (
            <div className="flex items-center justify-center h-64">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
            </div>
          ) : error ? (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg m-6">
              {error}
            </div>
          ) : filteredSales.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Date
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Customer
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Email
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Voucher Code
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Amount
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Status
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {filteredSales.map((sale) => (
                    <tr key={sale.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        <div className="flex items-center">
                          <Calendar size={14} className="mr-1" />
                          {new Date(sale.created_at).toLocaleDateString()}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900">{sale.purchaser_name}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {sale.purchaser_email}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          <span className="text-sm font-mono text-gray-900 mr-2">{sale.voucher_code}</span>
                          <button 
                            onClick={() => copyVoucherCode(sale.voucher_code)}
                            className="text-gray-400 hover:text-gray-600"
                            title="Copy code"
                          >
                            <Copy size={14} />
                          </button>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        €{sale.amount.toFixed(2)}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {sale.fulfilled ? (
                          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                            <CheckCircle size={12} className="mr-1" /> Fulfilled
                          </span>
                        ) : (
                          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                            <XCircle size={12} className="mr-1" /> Unfulfilled
                          </span>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        <button
                          onClick={() => handleToggleFulfillment(sale.id, sale.fulfilled)}
                          className={`px-3 py-1 rounded-md text-xs font-medium ${
                            sale.fulfilled
                              ? 'bg-yellow-100 text-yellow-800 hover:bg-yellow-200'
                              : 'bg-green-100 text-green-800 hover:bg-green-200'
                          }`}
                        >
                          {sale.fulfilled ? 'Mark Unfulfilled' : 'Mark Fulfilled'}
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="text-center py-12">
              <p className="text-gray-500">No sales found matching your criteria.</p>
            </div>
          )}
        </div>
      </div>
    </AdminLayout>
  );
};

export default AdminVoucherSalesPage;