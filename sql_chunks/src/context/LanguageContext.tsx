import React, { createContext, useContext, useState, ReactNode, useEffect } from 'react';

type Language = 'en' | 'de';

interface LanguageContextType {
  language: Language;
  setLanguage: (lang: Language) => void;
  t: (key: string) => string;
}

const translations = {
  en: {
    'nav.home': 'Home',
    'nav.photoshoots': 'Photoshoots',
    'nav.vouchers': 'Vouchers',
    'nav.blog': 'Blog',
    'nav.waitlist': 'Waitlist',
    'nav.contact': 'Contact',
    'nav.gallery': 'My Gallery',
    'nav.login': 'Login',
    'nav.logout': 'Logout',
    'newsletter.signup': 'Sign up for newsletter',
    'newsletter.thanks': 'Thank you for signing up! Please check your email for the voucher.',
    'newsletter.button': 'Sign up',
    'newsletter.placeholder': 'Your email address',
    'newsletter.error': 'An error occurred. Please try again later.'
  },
  de: {
    'nav.home': 'Startseite',
    'nav.photoshoots': 'Fotoshootings',
    'nav.vouchers': 'Gutscheine',
    'nav.blog': 'Blog',
    'nav.waitlist': 'Warteliste',
    'nav.contact': 'Kontakt',
    'nav.gallery': 'Meine Galerie',
    'nav.login': 'Anmelden',
    'nav.logout': 'Abmelden',
    'newsletter.signup': 'Sichern Sie sich einen Fotoshooting-Gutschein im Wert von €50 Print Guthaben.',
    'newsletter.thanks': 'Vielen Dank für Ihre Anmeldung! Bitte prüfen Sie Ihre E-Mails für den Gutschein.',
    'newsletter.button': 'Anmelden',
    'newsletter.placeholder': 'Ihre E-Mail-Adresse',
    'newsletter.error': 'Ein Fehler ist aufgetreten. Bitte versuchen Sie es später erneut.'
  }
};

const LanguageContext = createContext<LanguageContextType | undefined>(undefined);

export const LanguageProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [language, setLanguage] = useState<Language>(() => {
    // Try to get language from localStorage, default to 'de'
    const savedLang = localStorage.getItem('language');
    return (savedLang === 'en' || savedLang === 'de') ? savedLang : 'de';
  });

  useEffect(() => {
    // Save language preference to localStorage
    localStorage.setItem('language', language);
    // Update HTML lang attribute
    document.documentElement.lang = language;
  }, [language]);

  const t = (key: string): string => {
    return translations[language][key as keyof typeof translations['en']] || key;
  };

  return (
    <LanguageContext.Provider value={{ language, setLanguage, t }}>
      {children}
    </LanguageContext.Provider>
  );
};

export const useLanguage = () => {
  const context = useContext(LanguageContext);
  if (context === undefined) {
    throw new Error('useLanguage must be used within a LanguageProvider');
  }
  return context;
};