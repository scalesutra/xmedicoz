export interface NavItem {
  label: string;
  href: string;
  badge?: string;
}

export interface FeatureCard {
  id: string;
  iconName: string;
  badge: string;
  title: string;
  description: string;
  bulletPoints: string[];
  gradient: string;
}

export interface PricingPlan {
  id: string;
  name: string;
  tagline: string;
  popular?: boolean;
  monthlyPrice: number;
  annualPrice: number;
  features: string[];
  ctaLabel: string;
}

export interface Testimonial {
  name: string;
  pharmacy: string;
  location: string;
  quote: string;
  rating: number;
  verifiedChemist: boolean;
  avatarInitials: string;
}

export interface FaqItem {
  question: string;
  answer: string;
  category: string;
}
