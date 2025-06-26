export interface Gallery {
  id: string;
  title: string;
  slug: string;
  coverImage: string | null;
  passwordHash: string | null;
  downloadEnabled: boolean;
  clientId: string;
  createdAt: string;
  updatedAt: string;
}

export interface GalleryImage {
  id: string;
  galleryId: string;
  originalUrl: string;
  displayUrl: string;
  thumbUrl: string;
  filename: string;
  sizeBytes: number;
  contentType: string;
  capturedAt: string | null;
  orderIndex: number;
  createdAt: string;
  uploadedAt: string;
  sharedToTogninja: boolean;
  isFavorite?: boolean;
}

export interface GalleryVisitor {
  id: string;
  galleryId: string;
  email: string;
  firstName?: string;
  lastName?: string;
  accessToken: string;
  createdAt: string;
}

export interface ImageAction {
  id: string;
  visitorId: string;
  imageId: string;
  action: 'VIEW' | 'FAVORITE' | 'DOWNLOAD';
  createdAt: string;
}

export interface GalleryStats {
  uniqueVisitors: number;
  totalViews: number;
  totalFavorites: number;
  totalDownloads: number;
  dailyStats: {
    date: string;
    views: number;
    favorites: number;
    downloads: number;
  }[];
  topImages: {
    imageId: string;
    thumbUrl: string;
    views: number;
    favorites: number;
    downloads: number;
  }[];
}

export interface GalleryFormData {
  title: string;
  password?: string;
  downloadEnabled: boolean;
  coverImage?: File | null;
}

export interface GalleryAuthData {
  email: string;
  firstName?: string;
  lastName?: string;
  password?: string;
}

export interface GalleryAccessLog {
  id: string;
  galleryId: string;
  email: string;
  firstName?: string;
  lastName?: string;
  accessedAt: string;
  ipAddress?: string;
  userAgent?: string;
}