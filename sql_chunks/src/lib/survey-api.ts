import { supabase } from './supabase';
import { 
  Survey, 
  SurveyQuestion, 
  SurveyResponse, 
  SurveyTemplate, 
  SurveyAnalytics,
  SurveyListResponse,
  SurveyAnalyticsResponse,
  QuestionType,
  QuestionTypeDefinition,
  SurveyExportOptions
} from '../types/survey';

// Survey Management
export const surveyApi = {
  // Get all surveys
  async getSurveys(page = 1, limit = 10, status?: string, search?: string): Promise<SurveyListResponse> {
    let query = supabase
      .from('surveys')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false });

    if (status && status !== 'all') {
      query = query.eq('status', status);
    }

    if (search) {
      query = query.or(`title.ilike.%${search}%,description.ilike.%${search}%`);
    }

    const from = (page - 1) * limit;
    const to = from + limit - 1;

    const { data, error, count } = await query.range(from, to);

    if (error) throw error;

    return {
      surveys: data || [],
      total: count || 0,
      page,
      limit
    };
  },

  // Get survey by ID
  async getSurvey(id: string): Promise<Survey> {
    const { data, error } = await supabase
      .from('surveys')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;
    return data;
  },

  // Create new survey
  async createSurvey(survey: Omit<Survey, 'id' | 'createdAt' | 'updatedAt'>): Promise<Survey> {
    const { data, error } = await supabase
      .from('surveys')
      .insert([survey])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  // Update survey
  async updateSurvey(id: string, updates: Partial<Survey>): Promise<Survey> {
    const { data, error } = await supabase
      .from('surveys')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  // Delete survey
  async deleteSurvey(id: string): Promise<void> {
    const { error } = await supabase
      .from('surveys')
      .delete()
      .eq('id', id);

    if (error) throw error;
  },

  // Duplicate survey
  async duplicateSurvey(id: string, title?: string): Promise<Survey> {
    const original = await this.getSurvey(id);
    
    const duplicate = {
      ...original,
      title: title || `${original.title} (Copy)`,
      status: 'draft' as const,
      created_by: original.createdBy, // Will be overridden by auth
      analytics: undefined // Reset analytics
    };

    delete (duplicate as any).id;
    delete (duplicate as any).createdAt;
    delete (duplicate as any).updatedAt;

    return this.createSurvey(duplicate);
  },

  // Publish survey
  async publishSurvey(id: string): Promise<Survey> {
    return this.updateSurvey(id, {
      status: 'active',
      publishedAt: new Date().toISOString()
    });
  },

  // Pause survey
  async pauseSurvey(id: string): Promise<Survey> {
    return this.updateSurvey(id, { status: 'paused' });
  },

  // Close survey
  async closeSurvey(id: string): Promise<Survey> {
    return this.updateSurvey(id, {
      status: 'closed',
      closedAt: new Date().toISOString()
    });
  }
};

// Question Management
export const questionApi = {
  // Get question types
  getQuestionTypes(): QuestionTypeDefinition[] {
    return [
      {
        type: 'multiple_choice',
        name: 'Multiple Choice',
        description: 'Choose one option from a list',
        icon: 'circle-dot',
        category: 'choice',
        hasOptions: true,
        hasValidation: true,
        hasLogic: true
      },
      {
        type: 'checkboxes',
        name: 'Checkboxes',
        description: 'Choose multiple options from a list',
        icon: 'square-check',
        category: 'choice',
        hasOptions: true,
        hasValidation: true,
        hasLogic: true
      },
      {
        type: 'dropdown',
        name: 'Dropdown',
        description: 'Select from a dropdown menu',
        icon: 'chevron-down',
        category: 'choice',
        hasOptions: true,
        hasValidation: true,
        hasLogic: true
      },
      {
        type: 'text',
        name: 'Text Input',
        description: 'Single line text input',
        icon: 'type',
        category: 'text',
        hasOptions: false,
        hasValidation: true,
        hasLogic: true
      },
      {
        type: 'email',
        name: 'Email',
        description: 'Email address input with validation',
        icon: 'mail',
        category: 'text',
        hasOptions: false,
        hasValidation: true,
        hasLogic: true
      },
      {
        type: 'number',
        name: 'Number',
        description: 'Numeric input field',
        icon: 'hash',
        category: 'text',
        hasOptions: false,
        hasValidation: true,
        hasLogic: true
      },
      {
        type: 'date',
        name: 'Date',
        description: 'Date picker',
        icon: 'calendar',
        category: 'basic',
        hasOptions: false,
        hasValidation: true,
        hasLogic: true
      },
      {
        type: 'time',
        name: 'Time',
        description: 'Time picker',
        icon: 'clock',
        category: 'basic',
        hasOptions: false,
        hasValidation: true,
        hasLogic: true
      },
      {
        type: 'rating',
        name: 'Star Rating',
        description: 'Star rating scale',
        icon: 'star',
        category: 'rating',
        hasOptions: false,
        hasValidation: true,
        hasLogic: true
      },
      {
        type: 'scale',
        name: 'Linear Scale',
        description: 'Numbered scale rating',
        icon: 'minus',
        category: 'rating',
        hasOptions: false,
        hasValidation: true,
        hasLogic: true
      },
      {
        type: 'net_promoter_score',
        name: 'Net Promoter Score',
        description: '0-10 recommendation scale',
        icon: 'trending-up',
        category: 'rating',
        hasOptions: false,
        hasValidation: true,
        hasLogic: true
      },
      {
        type: 'likert_scale',
        name: 'Likert Scale',
        description: 'Agreement scale (Strongly Agree to Strongly Disagree)',
        icon: 'scale',
        category: 'rating',
        hasOptions: false,
        hasValidation: true,
        hasLogic: true
      },
      {
        type: 'ranking',
        name: 'Ranking',
        description: 'Drag and drop to rank options',
        icon: 'list-ordered',
        category: 'advanced',
        hasOptions: true,
        hasValidation: true,
        hasLogic: true,
        premium: true
      },
      {
        type: 'matrix',
        name: 'Matrix/Grid',
        description: 'Multiple questions with same answer choices',
        icon: 'grid-3x3',
        category: 'advanced',
        hasOptions: true,
        hasValidation: true,
        hasLogic: true,
        premium: true
      },
      {
        type: 'file_upload',
        name: 'File Upload',
        description: 'Upload files or images',
        icon: 'upload',
        category: 'advanced',
        hasOptions: false,
        hasValidation: true,
        hasLogic: true,
        premium: true
      },
      {
        type: 'slider',
        name: 'Slider',
        description: 'Interactive slider input',
        icon: 'sliders',
        category: 'advanced',
        hasOptions: false,
        hasValidation: true,
        hasLogic: true,
        premium: true
      },
      {
        type: 'image_choice',
        name: 'Image Choice',
        description: 'Choose from image options',
        icon: 'image',
        category: 'advanced',
        hasOptions: true,
        hasValidation: true,
        hasLogic: true,
        premium: true
      },
      {
        type: 'contact_info',
        name: 'Contact Information',
        description: 'Name, email, phone in one field',
        icon: 'user',
        category: 'advanced',
        hasOptions: false,
        hasValidation: true,
        hasLogic: true
      },
      {
        type: 'address',
        name: 'Address',
        description: 'Complete address form',
        icon: 'map-pin',
        category: 'advanced',
        hasOptions: false,
        hasValidation: true,
        hasLogic: true
      }
    ];
  },

  // Create default question
  createDefaultQuestion(type: QuestionType, order: number): Partial<SurveyQuestion> {
    const baseQuestion = {
      type,
      title: '',
      description: '',
      required: false,
      order,
      options: [],
      validation: {},
      logic: {},
      settings: {}
    };

    switch (type) {
      case 'multiple_choice':
      case 'checkboxes':
      case 'dropdown':
        return {
          ...baseQuestion,
          options: [
            { id: crypto.randomUUID(), text: 'Option 1' },
            { id: crypto.randomUUID(), text: 'Option 2' }
          ]
        };
      
      case 'rating':
        return {
          ...baseQuestion,
          settings: {
            startValue: 1,
            endValue: 5,
            showLabels: true
          }
        };
      
      case 'scale':
        return {
          ...baseQuestion,
          settings: {
            startValue: 1,
            endValue: 10,
            scaleLabels: ['Not at all likely', 'Extremely likely']
          }
        };
      
      case 'net_promoter_score':
        return {
          ...baseQuestion,
          settings: {
            startValue: 0,
            endValue: 10,
            scaleLabels: ['Not at all likely', 'Extremely likely']
          }
        };
      
      case 'likert_scale':
        return {
          ...baseQuestion,
          options: [
            { id: crypto.randomUUID(), text: 'Strongly Disagree' },
            { id: crypto.randomUUID(), text: 'Disagree' },
            { id: crypto.randomUUID(), text: 'Neutral' },
            { id: crypto.randomUUID(), text: 'Agree' },
            { id: crypto.randomUUID(), text: 'Strongly Agree' }
          ]
        };
      
      case 'matrix':
        return {
          ...baseQuestion,
          settings: {
            matrixRows: ['Row 1', 'Row 2'],
            matrixColumns: ['Column 1', 'Column 2', 'Column 3']
          }
        };
      
      case 'file_upload':
        return {
          ...baseQuestion,
          settings: {
            allowMultipleFiles: false,
            maxFileSize: 5,
            acceptedFileTypes: ['image/*', 'application/pdf']
          }
        };
      
      default:
        return baseQuestion;
    }
  }
};

// Response Management
export const responseApi = {
  // Get survey responses
  async getResponses(surveyId: string, page = 1, limit = 50): Promise<{ responses: SurveyResponse[]; total: number }> {
    const from = (page - 1) * limit;
    const to = from + limit - 1;

    const { data, error, count } = await supabase
      .from('survey_responses')
      .select('*', { count: 'exact' })
      .eq('survey_id', surveyId)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error) throw error;

    return {
      responses: data || [],
      total: count || 0
    };
  },

  // Get single response
  async getResponse(id: string): Promise<SurveyResponse> {
    const { data, error } = await supabase
      .from('survey_responses')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;
    return data;
  },

  // Submit response
  async submitResponse(response: Omit<SurveyResponse, 'id' | 'startedAt'>): Promise<SurveyResponse> {
    const { data, error } = await supabase
      .from('survey_responses')
      .insert([{ ...response, started_at: new Date().toISOString() }])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  // Update response (for partial saves)
  async updateResponse(id: string, updates: Partial<SurveyResponse>): Promise<SurveyResponse> {
    const { data, error } = await supabase
      .from('survey_responses')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  // Delete response
  async deleteResponse(id: string): Promise<void> {
    const { error } = await supabase
      .from('survey_responses')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
};

// Analytics
export const analyticsApi = {
  // Get survey analytics
  async getSurveyAnalytics(surveyId: string): Promise<SurveyAnalyticsResponse> {
    // This would typically call multiple endpoints or a complex query
    // For now, we'll simulate the data structure
    
    const { data: responses, error } = await supabase
      .from('survey_responses')
      .select('*')
      .eq('survey_id', surveyId);

    if (error) throw error;

    const totalCompletes = responses?.filter(r => r.status === 'completed').length || 0;
    const totalStarts = responses?.length || 0;
    
    const analytics: SurveyAnalytics = {
      totalViews: totalStarts * 1.2, // Simulate views > starts
      totalStarts,
      totalCompletes,
      completionRate: totalStarts > 0 ? (totalCompletes / totalStarts) * 100 : 0,
      averageTime: 180, // 3 minutes average
      dropOffPoints: [],
      responsesByDate: [],
      deviceBreakdown: {
        desktop: Math.floor(totalStarts * 0.6),
        tablet: Math.floor(totalStarts * 0.15),
        mobile: Math.floor(totalStarts * 0.25)
      },
      locationBreakdown: [
        { country: 'Austria', count: Math.floor(totalStarts * 0.8), percentage: 80 },
        { country: 'Germany', count: Math.floor(totalStarts * 0.15), percentage: 15 },
        { country: 'Other', count: Math.floor(totalStarts * 0.05), percentage: 5 }
      ]
    };

    const insights = [
      {
        type: 'completion_rate' as const,
        title: 'Completion Rate',
        description: `${analytics.completionRate.toFixed(1)}% of people who started completed the survey`,
        value: analytics.completionRate,
        trend: analytics.completionRate > 70 ? 'up' as const : 'down' as const,
        recommendation: analytics.completionRate < 70 ? 'Consider shortening your survey or improving question clarity' : undefined
      }
    ];

    return {
      analytics,
      responses: responses || [],
      insights
    };
  },

  // Export responses
  async exportResponses(surveyId: string, options: SurveyExportOptions): Promise<Blob> {
    // This would generate and return the export file
    // For now, we'll return a placeholder
    const { responses } = await responseApi.getResponses(surveyId, 1, 1000);
    
    if (options.format === 'csv') {
      const csv = this.generateCSV(responses);
      return new Blob([csv], { type: 'text/csv' });
    }
    
    if (options.format === 'json') {
      const json = JSON.stringify(responses, null, 2);
      return new Blob([json], { type: 'application/json' });
    }

    throw new Error(`Export format ${options.format} not supported`);
  },

  // Generate CSV from responses
  generateCSV(responses: SurveyResponse[]): string {
    if (responses.length === 0) return '';

    const headers = ['Response ID', 'Started At', 'Completed At', 'Status', 'Email'];
    const rows = responses.map(response => [
      response.id,
      response.startedAt,
      response.completedAt || '',
      response.status,
      response.email || ''
    ]);

    const csvContent = [headers, ...rows]
      .map(row => row.map(field => `"${field}"`).join(','))
      .join('\n');

    return csvContent;
  }
};

// Templates
export const templateApi = {
  // Get survey templates
  async getTemplates(category?: string): Promise<SurveyTemplate[]> {
    let query = supabase
      .from('survey_templates')
      .select('*')
      .order('usage_count', { ascending: false });

    if (category && category !== 'all') {
      query = query.eq('category', category);
    }

    const { data, error } = await query;
    if (error) throw error;

    return data || [];
  },

  // Get template by ID
  async getTemplate(id: string): Promise<SurveyTemplate> {
    const { data, error } = await supabase
      .from('survey_templates')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;
    return data;
  },
  // Create survey from template
  async createFromTemplate(templateId: string, title: string): Promise<Survey> {
    const template = await this.getTemplate(templateId);
    
    const survey = {
      ...template.survey,
      title,
      status: 'draft' as const,
      createdBy: '', // Will be set by auth
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    return surveyApi.createSurvey(survey);
  }
};

// Utility functions
export const surveyUtils = {
  // Validate survey before publishing
  validateSurvey(survey: Survey): string[] {
    const errors: string[] = [];

    if (!survey.title.trim()) {
      errors.push('Survey title is required');
    }

    if (survey.pages.length === 0) {
      errors.push('Survey must have at least one page');
    }

    const hasQuestions = survey.pages.some(page => page.questions.length > 0);
    if (!hasQuestions) {
      errors.push('Survey must have at least one question');
    }

    // Validate each question
    survey.pages.forEach((page, pageIndex) => {
      page.questions.forEach((question, questionIndex) => {
        if (!question.title.trim()) {
          errors.push(`Question ${questionIndex + 1} on page ${pageIndex + 1} needs a title`);
        }

        if (question.type === 'multiple_choice' || question.type === 'checkboxes' || question.type === 'dropdown') {
          if (!question.options || question.options.length < 2) {
            errors.push(`Question "${question.title}" needs at least 2 options`);
          }
        }
      });
    });

    return errors;
  },

  // Generate shareable link
  generateShareLink(surveyId: string, customUrl?: string): string {
    const baseUrl = window.location.origin;
    return customUrl 
      ? `${baseUrl}/s/${customUrl}`
      : `${baseUrl}/survey/${surveyId}`;
  },

  // Calculate estimated completion time
  estimateCompletionTime(survey: Survey): number {
    let totalTime = 0;

    survey.pages.forEach(page => {
      page.questions.forEach(question => {
        switch (question.type) {
          case 'text':
          case 'email':
          case 'number':
            totalTime += 15; // 15 seconds for text input
            break;
          case 'multiple_choice':
          case 'checkboxes':
          case 'dropdown':
            totalTime += 10; // 10 seconds for choice questions
            break;
          case 'rating':
          case 'scale':
            totalTime += 8; // 8 seconds for rating
            break;
          case 'matrix':
            const rows = question.settings?.matrixRows?.length || 1;
            totalTime += rows * 5; // 5 seconds per matrix row
            break;
          default:
            totalTime += 10;
        }
      });
    });

    return Math.ceil(totalTime / 60); // Return in minutes
  }
};
