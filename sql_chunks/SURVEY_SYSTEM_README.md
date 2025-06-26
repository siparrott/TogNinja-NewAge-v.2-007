# Survey Monkey-Style Questionnaire System

A comprehensive, feature-rich survey and questionnaire system built for the NEWAGEFrntEUI admin panel. This system provides Survey Monkey-style functionality with advanced question types, logic, analytics, and modern UI.

## 🚀 Features

### Core Features
- **Advanced Survey Builder**: Drag-and-drop interface with real-time preview
- **Rich Question Types**: 20+ question types including basic, advanced, and specialized options
- **Multi-Page Surveys**: Support for complex, multi-page survey flows
- **Real-Time Preview**: See how your survey looks as you build it
- **Mobile-Responsive**: Works perfectly on all devices

### Question Types

#### Basic Questions
- **Text Input**: Single-line text responses
- **Multiple Choice**: Radio button selections
- **Checkboxes**: Multiple option selections
- **Dropdown**: Select from dropdown menu
- **Email**: Email validation
- **Phone**: Phone number input
- **Number**: Numeric input only
- **Date**: Date picker
- **Time**: Time picker

#### Advanced Questions
- **Rating**: Star-based rating system
- **Scale**: Numeric scale (1-10)
- **Ranking**: Drag-and-drop ranking
- **Matrix**: Grid of questions
- **Slider**: Interactive slider input
- **Image Choice**: Select from images
- **File Upload**: Document/image uploads

#### Specialized Questions
- **Net Promoter Score (NPS)**: Standard NPS question
- **Contact Info**: Structured contact forms
- **Address**: Address input with validation

### Survey Management
- **Survey Templates**: Pre-built survey templates
- **Survey Collections**: Group related surveys
- **Status Management**: Draft, Active, Paused, Closed, Archived
- **Duplicate & Copy**: Easy survey replication
- **Bulk Operations**: Manage multiple surveys at once

### Advanced Settings
- **Access Control**: Anonymous vs. authenticated responses
- **Response Limits**: Control multiple submissions
- **Time Limits**: Set survey completion deadlines
- **Progress Indicators**: Show completion progress
- **Custom Styling**: Brand your surveys
- **Skip Logic**: Conditional question flow (planned)
- **Branching**: Complex survey paths (planned)

### Analytics & Reporting
- **Response Analytics**: Completion rates, drop-off points
- **Real-Time Reporting**: Live response tracking
- **Data Export**: CSV, Excel, JSON formats
- **Visual Charts**: Response visualization
- **Device Analytics**: Mobile vs. desktop usage
- **Geographic Data**: Location-based insights

### Integration Features
- **Share Links**: Public survey sharing
- **Embed Codes**: Embed in websites (planned)
- **API Access**: RESTful API for integrations
- **Webhook Support**: Real-time notifications (planned)
- **Email Distribution**: Send surveys via email (planned)

## 📂 File Structure

```
src/
├── components/admin/
│   ├── SurveyBuilderV3.tsx          # Main survey builder component
│   └── [other admin components]
├── pages/admin/
│   ├── QuestionnairesPage.tsx       # Survey management page
│   └── [other admin pages]
├── pages/
│   ├── SurveyTakingPage.tsx         # Public survey taking interface
│   └── [other pages]
├── types/
│   └── survey.ts                    # Complete type definitions
├── lib/
│   └── survey-api.ts                # API functions for surveys
└── [other directories]
```

## 🔧 Core Components

### SurveyBuilderV3.tsx
The main survey builder component featuring:
- Tabbed interface (Questions, Settings, Preview)
- Question type selector with categories
- Drag-and-drop question reordering
- Real-time question editing
- Live preview functionality
- Settings configuration

### QuestionnairesPage.tsx
Survey management interface with:
- Survey list with filtering and search
- Status management
- Bulk operations
- Analytics access
- Share link generation

### SurveyTakingPage.tsx
Public survey interface featuring:
- Clean, responsive design
- Progress tracking
- Multi-page navigation
- Answer validation
- Completion tracking

## 🗄️ Database Schema

The system uses Supabase with the following main tables:

### surveys
```sql
- id (uuid, primary key)
- title (text)
- description (text)
- status (enum: draft, active, paused, closed, archived)
- pages (jsonb) -- Survey pages and questions
- settings (jsonb) -- Survey configuration
- created_by (uuid, foreign key)
- created_at (timestamp)
- updated_at (timestamp)
```

### survey_responses
```sql
- id (uuid, primary key)
- survey_id (uuid, foreign key)
- respondent_id (uuid, optional)
- status (enum: started, completed, partial)
- answers (jsonb) -- Response data
- started_at (timestamp)
- completed_at (timestamp)
- metadata (jsonb) -- Device, location, etc.
```

### survey_templates
```sql
- id (uuid, primary key)
- name (text)
- description (text)
- category (text)
- survey (jsonb) -- Template survey structure
- usage_count (integer)
```

## 🎯 Usage Guide

### Creating a Survey

1. **Access the Survey Manager**
   ```
   Navigate to Admin Panel → Surveys
   ```

2. **Create New Survey**
   ```
   Click "Create Survey" button
   Enter survey title and description
   ```

3. **Add Questions**
   ```
   Click "Add Question"
   Choose question type from categories
   Configure question settings
   Add options for choice questions
   Set required status
   ```

4. **Configure Settings**
   ```
   Set access permissions
   Configure display options
   Set completion message
   ```

5. **Preview & Test**
   ```
   Use Preview tab to test survey
   Check question flow
   Verify responsive design
   ```

6. **Publish Survey**
   ```
   Set status to "Active"
   Copy share link
   Distribute to respondents
   ```

### Managing Responses

1. **View Response Analytics**
   ```
   Click analytics icon for any survey
   View completion rates
   Check drop-off points
   Analyze device usage
   ```

2. **Export Data**
   ```
   Use export functions for data analysis
   Choose format (CSV, Excel, JSON)
   Include/exclude incomplete responses
   ```

## 🛠️ API Reference

### Survey Management

```typescript
// Get all surveys
surveyApi.getSurveys(page, limit, status, search)

// Get single survey
surveyApi.getSurvey(id)

// Create survey
surveyApi.createSurvey(surveyData)

// Update survey
surveyApi.updateSurvey(id, updates)

// Delete survey
surveyApi.deleteSurvey(id)

// Duplicate survey
surveyApi.duplicateSurvey(id)
```

### Response Management

```typescript
// Submit response
responseApi.submitResponse(responseData)

// Get responses
responseApi.getResponses(surveyId, page, limit)

// Get analytics
analyticsApi.getSurveyAnalytics(surveyId)

// Export data
surveyApi.exportResponses(surveyId, options)
```

## 🎨 Customization

### Styling
The system uses Tailwind CSS for styling. Customize by:
- Modifying color schemes in components
- Adding custom CSS classes
- Using the survey settings for basic branding

### Question Types
Add new question types by:
1. Defining the type in `survey.ts`
2. Adding render logic in `SurveyBuilderV3.tsx`
3. Adding response handling in `SurveyTakingPage.tsx`

### Templates
Create survey templates by:
1. Building a survey in the builder
2. Exporting the structure
3. Adding to the template system

## 🔜 Planned Features

### Advanced Logic
- **Skip Logic**: Show/hide questions based on answers
- **Branching**: Complex survey paths
- **Piping**: Use answers in subsequent questions
- **Randomization**: Randomize question/option order

### Enhanced Analytics
- **A/B Testing**: Test different survey versions
- **Heat Maps**: Visual response patterns
- **Sentiment Analysis**: Analyze text responses
- **Real-time Dashboards**: Live response monitoring

### Distribution
- **Email Campaigns**: Built-in email distribution
- **Social Sharing**: Share via social media
- **QR Codes**: Generate QR codes for surveys
- **Embed Widgets**: Easy website embedding

### Integration
- **Webhooks**: Real-time notifications
- **Zapier Integration**: Connect to 1000+ apps
- **API Webhooks**: Custom integrations
- **CRM Sync**: Sync with popular CRMs

## 🐛 Troubleshooting

### Common Issues

1. **Survey Not Loading**
   - Check survey status (must be "Active")
   - Verify survey ID in URL
   - Check network connectivity

2. **Responses Not Saving**
   - Ensure all required fields are completed
   - Check database permissions
   - Verify API endpoints

3. **Builder Issues**
   - Clear browser cache
   - Check for JavaScript errors
   - Verify component imports

### Performance Tips

1. **Large Surveys**
   - Use pagination for long surveys
   - Optimize image sizes
   - Consider performance impact of complex logic

2. **High Response Volume**
   - Monitor database performance
   - Consider response archiving
   - Use analytics sampling for large datasets

## 📈 Best Practices

### Survey Design
- Keep surveys focused and concise
- Use clear, unambiguous questions
- Test on multiple devices
- Consider accessibility requirements

### Question Flow
- Start with easy questions
- Group related questions together
- Use progress indicators for long surveys
- End with optional feedback questions

### Data Collection
- Be transparent about data usage
- Provide privacy information
- Allow anonymous responses when appropriate
- Regular data cleanup and archiving

## 🤝 Contributing

To contribute to the survey system:

1. Follow the existing code patterns
2. Add comprehensive type definitions
3. Include error handling
4. Test on multiple devices
5. Update documentation

## 📝 License

This survey system is part of the NEWAGEFrntEUI project and follows the same licensing terms.

---

For support or questions about the survey system, please refer to the main project documentation or contact the development team.
