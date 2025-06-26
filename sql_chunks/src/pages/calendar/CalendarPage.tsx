import React from 'react';
import NextGenCalendar from '../../components/calendar/NextGenCalendar';

const CalendarPage: React.FC = () => {
  return (
    <div className="min-h-screen bg-gray-50">
      <NextGenCalendar className="h-full" />
    </div>
  );
};

export default CalendarPage;
