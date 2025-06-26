import React, { useState, useEffect } from 'react';
import AdminLayout from '../../components/admin/AdminLayout';
import SurveyBuilder from '../../components/admin/SurveyBuilderV3';
import { supabase } from '../../lib/supabase';
import { surveyApi } from '../../lib/survey-api';
import { Survey, SurveyQuestion, SurveyPage } from '../../types/survey';
import { 
  Plus, 
  Search, 
  Filter, 
  Eye, 
  Edit, 
  Copy, 
  Trash2, 
  ClipboardList, 
  Users,
  Link,
  Calendar,
  Loader2,
  AlertCircle,
  BarChart3,
  Settings,
  ExternalLink,
  Download
} from 'lucide-react';

// Legacy interface for backward compatibility
interface Questionnaire {
  id: string;
  title: string;
  description?: string;
  questions: any[];
  status: 'active' | 'inactive' | 'archived';
  created_by: string;
  created_at: string;
  updated_at: string;
  response_count?: number;
}

const QuestionnairesPage: React.FC = () => {
  const [surveys, setSurveys] = useState<Survey[]>([]);
  const [filteredSurveys, setFilteredSurveys] = useState<Survey[]>([]);
  const [questionnaires, setQuestionnaires] = useState<Survey[]>([]);
  const [filteredQuestionnaires, setFilteredQuestionnaires] = useState<Survey[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showSurveyBuilder, setShowSurveyBuilder] = useState(false);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [editingSurvey, setEditingSurvey] = useState<Survey | undefined>(undefined);
  const [deleteConfirmation, setDeleteConfirmation] = useState<string | null>(null);
  const [builderLoading, setBuilderLoading] = useState(false);
  useEffect(() => {
    fetchSurveys();
  }, []);

  useEffect(() => {
    filterSurveys();
    filterQuestionnaires();
  }, [surveys, questionnaires, searchTerm, statusFilter]);

  const filterSurveys = () => {
    let filtered = [...surveys];
    
    if (searchTerm) {
      filtered = filtered.filter(survey => 
        survey.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
        survey.description.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    if (statusFilter !== 'all') {
      filtered = filtered.filter(survey => survey.status === statusFilter);
    }

    setFilteredSurveys(filtered);
  };
  const fetchSurveys = async () => {
    try {
      setLoading(true);
      setError(null);
      
      // Create sample surveys/questionnaires with response counts
      const sampleSurveys: any[] = [
        {
          id: '1',
          title: 'Customer Satisfaction Survey',
          description: 'Measure customer satisfaction with our photography services',
          status: 'active',
          created_at: new Date('2025-06-01'),
          updated_at: new Date('2025-06-01'),
          questions: [],
          response_count: 23
        },
        {
          id: '2',
          title: 'Wedding Photography Feedback',
          description: 'Feedback form for wedding photography clients',
          status: 'inactive',
          created_at: new Date('2025-06-05'),
          updated_at: new Date('2025-06-05'),
          questions: [],
          response_count: 8
        },
        {
          id: '3',
          title: 'Event Photography Review',
          description: 'Review form for corporate event photography',
          status: 'active',
          created_at: new Date('2025-06-10'),
          updated_at: new Date('2025-06-10'),
          questions: [],
          response_count: 15
        }
      ];
      
      setQuestionnaires(sampleSurveys);
      setFilteredQuestionnaires(sampleSurveys);
      
      // Also set surveys for the survey builder
      const surveyData: Survey[] = sampleSurveys.map(q => ({
        id: q.id,
        title: q.title,
        description: q.description,
        status: q.status === 'active' ? 'published' : 'draft',
        createdAt: new Date(q.created_at),
        updatedAt: new Date(q.updated_at),
        pages: [],
        settings: {
          allowMultipleResponses: false,
          requireLogin: false,
          isAnonymous: true,
          welcomeMessage: 'Welcome to our survey',
          thankYouMessage: 'Thank you for your feedback'
        },
        branding: {
          logo: '',
          primaryColor: '#3B82F6',
          backgroundColor: '#FFFFFF'
        }
      }));
      
      setSurveys(surveyData);
      setFilteredSurveys(surveyData);
      
    } catch (err) {
      console.error('Error fetching questionnaires:', err);
      setError('Failed to load questionnaires. Using sample data.');
      
      // Fallback to empty arrays
      setQuestionnaires([]);
      setFilteredQuestionnaires([]);
      setSurveys([]);
      setFilteredSurveys([]);
    } finally {
      setLoading(false);
    }
  };

  const filterQuestionnaires = () => {
    let filtered = [...questionnaires];
    
    // Apply search filter
    if (searchTerm) {
      filtered = filtered.filter(questionnaire => 
        questionnaire.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (questionnaire.description && questionnaire.description.toLowerCase().includes(searchTerm.toLowerCase()))
      );
    }
    
    // Apply status filter
    if (statusFilter !== 'all') {
      filtered = filtered.filter(questionnaire => questionnaire.status === statusFilter);
    }
    
    setFilteredQuestionnaires(filtered);
  };
  const handleDeleteQuestionnaire = async (id: string) => {
    try {
      setLoading(true);
      
      // Remove from local state (for demo purposes)
      setQuestionnaires(prevQuestionnaires => prevQuestionnaires.filter((q: any) => q.id !== id));
      setFilteredQuestionnaires(prev => prev.filter((q: any) => q.id !== id));
      setDeleteConfirmation(null);
    } catch (err) {
      console.error('Error deleting questionnaire:', err);
      setError('Failed to delete questionnaire. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleDuplicateQuestionnaire = async (id: string) => {
    try {
      setLoading(true);
      
      // Find the questionnaire to duplicate
      const questionnaireToDuplicate = questionnaires.find((q: any) => q.id === id);
      
      if (!questionnaireToDuplicate) {
        throw new Error('Questionnaire not found');
      }
      
      // Create a new questionnaire based on the existing one
      const newQuestionnaire = {
        ...questionnaireToDuplicate,
        id: Date.now().toString(),
        title: `${questionnaireToDuplicate.title} (Copy)`,
        status: 'inactive',
        response_count: 0,
        created_at: new Date(),
        updated_at: new Date()
      };

      // Add to local state
      setQuestionnaires(prevQuestionnaires => [newQuestionnaire, ...prevQuestionnaires]);
      setFilteredQuestionnaires(prev => [newQuestionnaire, ...prev]);
      
      const { data: newQuestionnaireData, error: insertError } = await supabase
        .from('crm_questionnaires')
        .insert([newQuestionnaire])
        .select();
      
      if (insertError) throw insertError;
      
      // Add to local state
      setQuestionnaires(prevQuestionnaires => [
        { ...newQuestionnaireData[0], response_count: 0 },
        ...prevQuestionnaires
      ]);
    } catch (err) {
      console.error('Error duplicating questionnaire:', err);
      setError('Failed to duplicate questionnaire. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const getStatusBadge = (status: Questionnaire['status']) => {
    const statusConfig = {
      active: { bg: 'bg-green-100', text: 'text-green-800', label: 'Active' },
      inactive: { bg: 'bg-gray-100', text: 'text-gray-800', label: 'Inactive' },
      archived: { bg: 'bg-yellow-100', text: 'text-yellow-800', label: 'Archived' }
    };

    const config = statusConfig[status];
    return (
      <span className={`px-2 py-1 rounded-full text-xs font-medium ${config.bg} ${config.text}`}>
        {config.label}
      </span>
    );
  };

  const copyShareLink = (id: string) => {
    const shareUrl = `${window.location.origin}/questionnaire/${id}`;
    navigator.clipboard.writeText(shareUrl);
    alert('Share link copied to clipboard!');
  };

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-gray-900">Questionnaires</h1>
            <p className="text-gray-600">Create and manage client questionnaires</p>
          </div>
          <button
            onClick={() => setShowCreateModal(true)}
            className="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-lg flex items-center"
          >
            <Plus size={20} className="mr-2" />
            Create Questionnaire
          </button>
        </div>

        {/* Filters */}
        <div className="bg-white rounded-lg shadow p-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
              <input
                type="text"
                placeholder="Search questionnaires..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10 pr-4 py-2 w-full border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
              />
            </div>
            
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
            >
              <option value="all">All Statuses</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="archived">Archived</option>
            </select>

            <button className="flex items-center justify-center px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50">
              <Filter size={20} className="mr-2" />
              More Filters
            </button>
          </div>
        </div>

        {/* Error Message */}
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg flex items-start">
            <AlertCircle className="h-5 w-5 text-red-400 mt-0.5 mr-2" />
            <span>{error}</span>
          </div>
        )}

        {/* Questionnaires Grid */}
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <Loader2 className="h-8 w-8 text-purple-600 animate-spin" />
            <span className="ml-2 text-gray-600">Loading questionnaires...</span>
          </div>
        ) : filteredQuestionnaires.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredQuestionnaires.map((questionnaire) => (
              <div key={questionnaire.id} className="bg-white rounded-lg shadow-lg overflow-hidden">
                <div className="p-6">
                  <div className="flex justify-between items-start mb-4">
                    <h3 className="text-lg font-medium text-gray-900 truncate max-w-xs" title={questionnaire.title}>
                      {questionnaire.title}
                    </h3>
                    {getStatusBadge(questionnaire.status)}
                  </div>
                  
                  {questionnaire.description && (
                    <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                      {questionnaire.description}
                    </p>
                  )}
                  
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center text-sm text-gray-500">
                      <ClipboardList size={16} className="mr-1" />
                      {questionnaire.questions.length} {questionnaire.questions.length === 1 ? 'question' : 'questions'}
                    </div>
                    <div className="flex items-center text-sm text-gray-500">
                      <Users size={16} className="mr-1" />
                      {questionnaire.response_count} {questionnaire.response_count === 1 ? 'response' : 'responses'}
                    </div>
                  </div>
                  
                  <div className="text-xs text-gray-500 mb-4">
                    <div className="flex items-center">
                      <Calendar size={14} className="mr-1" />
                      Created {new Date(questionnaire.created_at).toLocaleDateString()}
                    </div>
                  </div>
                  
                  <div className="flex justify-between">
                    <div className="flex space-x-2">
                      <button className="text-blue-600 hover:text-blue-900" title="View">
                        <Eye size={18} />
                      </button>
                      <button className="text-green-600 hover:text-green-900" title="Edit">
                        <Edit size={18} />
                      </button>
                      <button 
                        onClick={() => copyShareLink(questionnaire.id)}
                        className="text-purple-600 hover:text-purple-900" 
                        title="Copy Share Link"
                      >
                        <Link size={18} />
                      </button>
                    </div>
                    <div className="flex space-x-2">
                      <button 
                        onClick={() => handleDuplicateQuestionnaire(questionnaire.id)}
                        className="text-blue-600 hover:text-blue-900" 
                        title="Duplicate"
                      >
                        <Copy size={18} />
                      </button>
                      <button 
                        onClick={() => setDeleteConfirmation(questionnaire.id)}
                        className="text-red-600 hover:text-red-900" 
                        title="Delete"
                      >
                        <Trash2 size={18} />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-12 bg-white rounded-lg shadow">
            <div className="mx-auto h-12 w-12 text-gray-400">
              <ClipboardList className="h-12 w-12 mx-auto" />
            </div>
            <h3 className="mt-2 text-sm font-medium text-gray-900">No questionnaires found</h3>
            <p className="mt-1 text-sm text-gray-500">
              {searchTerm || statusFilter !== 'all'
                ? 'Try adjusting your search or filter criteria.'
                : 'Get started by creating a new questionnaire.'}
            </p>
            <div className="mt-6">
              <button
                onClick={() => setShowCreateModal(true)}
                className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500"
              >
                <Plus className="-ml-1 mr-2 h-5 w-5" />
                Create Questionnaire
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Delete Confirmation Modal */}
      {deleteConfirmation && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Confirm Deletion</h3>
            <p className="text-gray-500 mb-6">
              Are you sure you want to delete this questionnaire? This action cannot be undone.
            </p>
            <div className="flex justify-end space-x-4">
              <button
                onClick={() => setDeleteConfirmation(null)}
                className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={() => deleteConfirmation && handleDeleteQuestionnaire(deleteConfirmation)}
                className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Create Questionnaire Modal would go here */}
    </AdminLayout>
  );
};

export default QuestionnairesPage;