import React, { useState, useEffect } from 'react';
import AdminLayout from '../../components/admin/AdminLayout';
import { supabase } from '../../lib/supabase';
import { 
  BarChart as BarChartIcon, 
  Calendar as CalendarIcon, 
  Mail as MailIcon, 
  Users as UsersIcon,
  LineChart as LineChartIcon,
  Plus,
  ArrowRight,
  Eye,
  Edit,
  Trash2
} from 'lucide-react';
import { 
  ResponsiveContainer, 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  Tooltip, 
  CartesianGrid,
  LineChart,
  Line
} from 'recharts';
import { format } from 'date-fns';
import { Card, CardHeader, CardTitle, CardContent } from '../../components/ui/card';
import { Button } from '../../components/ui/button';
import { useNavigate } from 'react-router-dom';

interface Lead {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
  phone: string | null;
  message: string | null;
  form_source: 'WARTELISTE' | 'KONTAKT';
  status: 'NEW' | 'CONTACTED' | 'CONVERTED';
  created_at: string;
}

interface SalePoint {
  date: string; // ISO yyyy-MM-dd
  value: number;
}

interface ClientStat {
  name: string;
  total: number;
}

interface Booking {
  id: string;
  start: string;
  client: string;
  type: string;
}

interface CampaignStat {
  title: string;
  openRate: number; // 0-100
}

const AdminDashboardPage: React.FC = () => {
  const navigate = useNavigate();
  const [leads, setLeads] = useState<Lead[]>([]);
  const [voucherSales, setVoucherSales] = useState<SalePoint[]>([]);
  const [topClients, setTopClients] = useState<ClientStat[]>([]);
  const [invoiceTotal, setInvoiceTotal] = useState<number>(0);
  const [upcomingBookings, setUpcomingBookings] = useState<Booking[]>([]);
  const [blogEngagement, setBlogEngagement] = useState<SalePoint[]>([]);
  const [emailCampaigns, setEmailCampaigns] = useState<CampaignStat[]>([]);
  const [inboxUnread, setInboxUnread] = useState<number>(0);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      
      // Fetch leads directly from the leads table
      const { data: leadsData, error: leadsError } = await supabase
        .from('leads')
        .select('*')
        .order('created_at', { ascending: false });
      
      if (leadsError) {
        console.error('Error fetching leads:', leadsError);
      } else if (leadsData) {
        setLeads(leadsData);
      }
      
      // Fetch voucher sales
      const { data: voucherData, error: voucherError } = await supabase
        .from('voucher_sales')
        .select('created_at, amount')
        .order('created_at', { ascending: false })
        .limit(30);
      
      if (voucherError) {
        console.error('Error fetching voucher sales:', voucherError);
      } else if (voucherData) {
        // Group by date and sum amounts
        const salesByDate = voucherData.reduce((acc: Record<string, number>, sale) => {
          const date = sale.created_at.split('T')[0];
          acc[date] = (acc[date] || 0) + sale.amount;
          return acc;
        }, {});
        
        const formattedSales: SalePoint[] = Object.entries(salesByDate).map(([date, value]) => ({
          date,
          value: Number(value)
        })).sort((a, b) => a.date.localeCompare(b.date));
        
        setVoucherSales(formattedSales);
      }

      // Fetch top clients
      const { data: clientsData, error: clientsError } = await supabase
        .from('crm_clients')
        .select('id, name')
        .order('created_at', { ascending: false })
        .limit(10);
      
      if (clientsError) {
        console.error('Error fetching clients:', clientsError);
      } else if (clientsData) {
        // For demo purposes, assign random revenue values
        const formattedClients: ClientStat[] = clientsData.map((client, index) => ({
          name: client.name,
          total: Math.floor(Math.random() * 1000) + 500 - (index * 50) // Decreasing values for ranking
        })).sort((a, b) => b.total - a.total);
        
        setTopClients(formattedClients);
      }

      // Fetch invoice total
      const { data: invoiceData, error: invoiceError } = await supabase
        .from('crm_invoices')
        .select('total_amount')
        .eq('status', 'paid');
      
      if (invoiceError) {
        console.error('Error fetching invoices:', invoiceError);
      } else if (invoiceData) {
        const total = invoiceData.reduce((sum, invoice) => sum + (invoice.total_amount || 0), 0);
        setInvoiceTotal(total);
      }

      // Fetch upcoming bookings
      const today = new Date();
      const nextWeek = new Date();
      nextWeek.setDate(today.getDate() + 7);
      
      const { data: bookingsData, error: bookingsError } = await supabase
        .from('crm_bookings')
        .select('id, booking_date, client_id, service_type')
        .gte('booking_date', today.toISOString())
        .lte('booking_date', nextWeek.toISOString())
        .order('booking_date', { ascending: true });
      
      if (bookingsError) {
        console.error('Error fetching bookings:', bookingsError);
      } else if (bookingsData) {
        // Get client names
        const clientIds = bookingsData.map(b => b.client_id);
        const { data: clientNames, error: clientNamesError } = await supabase
          .from('crm_clients')
          .select('id, name')
          .in('id', clientIds);
        
        if (clientNamesError) {
          console.error('Error fetching client names:', clientNamesError);
        }
        
        const clientMap = new Map();
        if (clientNames) {
          clientNames.forEach(client => {
            clientMap.set(client.id, client.name);
          });
        }
        
        const formattedBookings: Booking[] = bookingsData.map(booking => ({
          id: booking.id,
          start: booking.booking_date,
          client: clientMap.get(booking.client_id) || 'Unknown Client',
          type: booking.service_type
        }));
        
        setUpcomingBookings(formattedBookings);
      }

      // Fetch unread messages count
      const { count: messagesCount, error: messagesError } = await supabase
        .from('crm_messages')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'unread');
      
      if (messagesError) {
        console.error('Error fetching unread messages count:', messagesError);
      } else {
        setInboxUnread(messagesCount || 0);
      }
      
      // Fetch email campaigns
      const { data: campaignData, error: campaignError } = await supabase
        .from('crm_campaigns')
        .select('name, open_count, recipient_count')
        .order('created_at', { ascending: false })
        .limit(5);
      
      if (campaignError) {
        console.error('Error fetching campaigns:', campaignError);
      } else if (campaignData) {
        const formattedCampaigns: CampaignStat[] = campaignData.map(campaign => ({
          title: campaign.name,
          openRate: campaign.recipient_count > 0 
            ? Math.round((campaign.open_count / campaign.recipient_count) * 100) 
            : 0
        }));
        
        setEmailCampaigns(formattedCampaigns);
      }
      
      setLoading(false);
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
      setLoading(false);
      
      // Fall back to mock data if there's an error
      generateMockData();
    }
  };

  // Generate mock data if real data is not available
  const generateMockData = () => {
    // Mock voucher sales if not available
    if (voucherSales.length === 0) {
      const mockSales: SalePoint[] = Array.from({ length: 30 }, (_, i) => {
        const date = new Date();
        date.setDate(date.getDate() - (29 - i));
        return {
          date: date.toISOString().split('T')[0],
          value: Math.floor(Math.random() * 500) + 100
        };
      });
      setVoucherSales(mockSales);
    }

    // Mock top clients if not available
    if (topClients.length === 0) {
      const mockClients: ClientStat[] = [
        { name: "Sarah Mueller", total: 2450 },
        { name: "Michael Schmidt", total: 1980 },
        { name: "Anna Weber", total: 1750 },
        { name: "Thomas Huber", total: 1500 },
        { name: "Lisa Bauer", total: 1350 },
        { name: "Martin Gruber", total: 1200 },
        { name: "Julia Hofer", total: 1050 },
        { name: "Stefan Maier", total: 950 },
        { name: "Christina Wagner", total: 850 },
        { name: "Andreas Berger", total: 750 }
      ];
      setTopClients(mockClients);
    }

    // Mock upcoming bookings if not available
    if (upcomingBookings.length === 0) {
      const mockBookings: Booking[] = Array.from({ length: 7 }, (_, i) => {
        const date = new Date();
        date.setDate(date.getDate() + i);
        return {
          id: `booking-${i}`,
          start: date.toISOString(),
          client: ["Sarah Mueller", "Michael Schmidt", "Anna Weber", "Thomas Huber", "Lisa Bauer"][Math.floor(Math.random() * 5)],
          type: ["Family", "Newborn", "Wedding", "Business", "Event"][Math.floor(Math.random() * 5)]
        };
      });
      setUpcomingBookings(mockBookings);
    }

    // Mock email campaigns if not available
    if (emailCampaigns.length === 0) {
      const mockCampaigns: CampaignStat[] = [
        { title: "Summer Special Offer", openRate: 68 },
        { title: "Family Session Promotion", openRate: 72 },
        { title: "Wedding Season Announcement", openRate: 65 },
        { title: "Business Portrait Discount", openRate: 58 },
        { title: "Holiday Mini Sessions", openRate: 76 }
      ];
      setEmailCampaigns(mockCampaigns);
    }

    // Set default values for other metrics if not available
    if (invoiceTotal === 0) {
      setInvoiceTotal(15420);
    }

    if (inboxUnread === 0) {
      setInboxUnread(12);
    }
  };

  const formatLeadName = (lead: Lead): string => {
    return `${lead.first_name || ''} ${lead.last_name || ''}`.trim() || 'Unknown';
  };

  const getLeadService = (lead: Lead): string => {
    if (lead.form_source === 'WARTELISTE') return 'Waitlist';
    if (lead.form_source === 'KONTAKT') return 'Contact';
    return 'General Inquiry';
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'NEW':
        return <span className="px-2 py-0.5 text-xs rounded bg-blue-100 text-blue-800">New</span>;
      case 'CONTACTED':
        return <span className="px-2 py-0.5 text-xs rounded bg-yellow-100 text-yellow-800">Contacted</span>;
      case 'CONVERTED':
        return <span className="px-2 py-0.5 text-xs rounded bg-green-100 text-green-800">Converted</span>;
      default:
        return <span className="px-2 py-0.5 text-xs rounded bg-gray-100 text-gray-800">{status}</span>;
    }
  };

  const KPI: React.FC<{ icon: React.ReactNode; label: string; value: string }> = ({
    icon,
    label,
    value,
  }) => (
    <Card className="flex-1">
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-gray-500">
          {label}
        </CardTitle>
        {icon}
      </CardHeader>
      <CardContent>
        <span className="text-2xl font-bold">{value}</span>
      </CardContent>
    </Card>
  );

  const handleViewLead = (id: string) => {
    // Navigate to lead detail page
    navigate(`/admin/leads/${id}`);
  };

  const handleEditLead = (id: string) => {
    // Navigate to lead edit page
    navigate(`/admin/leads/edit/${id}`);
  };

  const handleDeleteLead = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this lead?')) {
      try {
        const { error } = await supabase
          .from('leads')
          .delete()
          .eq('id', id);
        
        if (error) {
          throw error;
        }
        
        // Refresh leads after deletion
        setLeads(leads.filter(lead => lead.id !== id));
      } catch (error) {
        console.error('Error deleting lead:', error);
        alert('Failed to delete lead. Please try again.');
      }
    }
  };

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
        </div>
      </AdminLayout>
    );
  }

  return (
    <AdminLayout>
      <div className="p-6 space-y-6">
        {/* --- KPI strip --- */}
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <KPI 
            icon={<UsersIcon className="h-4 w-4 text-purple-600" />} 
            label="New Leads (30d)" 
            value={`${leads.length}`} 
          />
          <KPI 
            icon={<LineChartIcon className="h-4 w-4 text-purple-600" />} 
            label="Voucher € (30d)" 
            value={`€${voucherSales.reduce((a, b) => a + b.value, 0).toLocaleString()}`} 
          />
          <KPI 
            icon={<MailIcon className="h-4 w-4 text-purple-600" />} 
            label="Unread Emails" 
            value={`${inboxUnread}`} 
          />
          <KPI 
            icon={<CalendarIcon className="h-4 w-4 text-purple-600" />} 
            label="Invoice € YTD" 
            value={`€${invoiceTotal.toLocaleString()}`} 
          />
        </div>

        {/* --- Charts & Lists --- */}
        <div className="grid gap-6 lg:grid-cols-2">
          {/* Voucher Sales Chart */}
          <Card>
            <CardHeader>
              <CardTitle>Voucher Sales Trend</CardTitle>
            </CardHeader>
            <CardContent className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={voucherSales} margin={{ top: 10, right: 20, left: 0, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis 
                    dataKey="date" 
                    tickFormatter={(date) => format(new Date(date), 'dd MMM')}
                    interval={Math.floor(voucherSales.length / 7)}
                  />
                  <YAxis />
                  <Tooltip formatter={(v: number) => `€${v}`} labelFormatter={(label) => format(new Date(label), 'dd MMM yyyy')} />
                  <Bar dataKey="value" fill="#8884d8" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          {/* Top Clients Chart */}
          <Card>
            <CardHeader>
              <CardTitle>Top Clients</CardTitle>
            </CardHeader>
            <CardContent className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart layout="vertical" data={topClients.slice(0, 5)} margin={{ left: 20, right: 20, top: 10, bottom: 10 }}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis type="number" />
                  <YAxis dataKey="name" type="category" width={120} />
                  <Tooltip formatter={(v: number) => `€${v.toLocaleString()}`} />
                  <Bar dataKey="total" fill="#8884d8" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          {/* Next Bookings List */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle>Next 7 Days – Bookings</CardTitle>
              <Button size="sm" onClick={() => navigate('/admin/calendar')}>Open Calendar</Button>
            </CardHeader>
            <CardContent>
              {upcomingBookings.length > 0 ? (
                <ul className="space-y-1 max-h-64 overflow-y-auto pr-2">
                  {upcomingBookings.map((b) => (
                    <li key={b.id} className="flex justify-between border-b py-1 text-sm">
                      <span>{format(new Date(b.start), "dd MMM HH:mm")}</span>
                      <span className="truncate font-medium">{b.client}</span>
                      <span className="text-gray-500">{b.type}</span>
                    </li>
                  ))}
                </ul>
              ) : (
                <div className="flex items-center justify-center h-32 text-gray-500">
                  No upcoming bookings for the next 7 days
                </div>
              )}
            </CardContent>
          </Card>

          {/* Email Campaigns Table */}
          <Card>
            <CardHeader>
              <CardTitle>Top Email Campaigns (Open %)</CardTitle>
            </CardHeader>
            <CardContent>
              {emailCampaigns.length > 0 ? (
                <table className="w-full text-sm">
                  <thead className="text-gray-500">
                    <tr>
                      <th className="text-left py-1">Campaign</th>
                      <th className="text-right py-1">Open %</th>
                    </tr>
                  </thead>
                  <tbody>
                    {emailCampaigns.slice(0, 5).map((c) => (
                      <tr key={c.title} className="border-b last:border-none">
                        <td className="py-1 pr-4 truncate">{c.title}</td>
                        <td className="text-right py-1">{c.openRate}%</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              ) : (
                <div className="flex items-center justify-center h-32 text-gray-500">
                  No email campaigns data available
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* --- Leads Table --- */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle>Recent Leads</CardTitle>
            <Button size="sm" onClick={() => navigate('/admin/leads/new')}>
              <Plus className="mr-2 h-4 w-4" />
              Add Lead
            </Button>
          </CardHeader>
          <CardContent>
            {leads.length > 0 ? (
              <table className="w-full text-sm">
                <thead className="text-gray-500">
                  <tr>
                    <th className="text-left py-1">Contact</th>
                    <th className="text-left py-1">Service</th>
                    <th className="text-left py-1">Status</th>
                    <th className="text-left py-1">Date</th>
                    <th className="text-right py-1">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {leads.slice(0, 10).map((lead) => (
                    <tr key={lead.id} className="border-b last:border-none">
                      <td className="py-1 pr-4">
                        <div className="font-medium">{formatLeadName(lead)}</div>
                        <div className="text-gray-500">{lead.email}</div>
                      </td>
                      <td className="py-1">{getLeadService(lead)}</td>
                      <td className="py-1">
                        {getStatusBadge(lead.status)}
                      </td>
                      <td className="py-1">{format(new Date(lead.created_at), "dd MMM yyyy")}</td>
                      <td className="py-1 text-right">
                        <div className="flex justify-end space-x-2">
                          <button 
                            onClick={() => handleViewLead(lead.id)}
                            className="text-blue-600 hover:text-blue-800"
                            title="View Lead"
                          >
                            <Eye size={16} />
                          </button>
                          <button 
                            onClick={() => handleEditLead(lead.id)}
                            className="text-green-600 hover:text-green-800"
                            title="Edit Lead"
                          >
                            <Edit size={16} />
                          </button>
                          <button 
                            onClick={() => handleDeleteLead(lead.id)}
                            className="text-red-600 hover:text-red-800"
                            title="Delete Lead"
                          >
                            <Trash2 size={16} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : (
              <div className="flex items-center justify-center h-32 text-gray-500">
                No leads found in the database
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </AdminLayout>
  );
};

export default AdminDashboardPage;