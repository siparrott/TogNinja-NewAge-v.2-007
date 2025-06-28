import { 
  pgTable, 
  text, 
  serial, 
  integer, 
  boolean, 
  uuid, 
  timestamp, 
  decimal, 
  jsonb,
  date,
  pgEnum
} from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";
import { relations } from "drizzle-orm";

// Auth Users table (core authentication)
export const users = pgTable("users", {
  id: uuid("id").primaryKey().defaultRandom(),
  email: text("email").unique().notNull(),
  password: text("password"),
  firstName: text("first_name"),
  lastName: text("last_name"),
  avatar: text("avatar"),
  isAdmin: boolean("is_admin").default(false),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Admin Users table
export const adminUsers = pgTable("admin_users", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").references(() => users.id).notNull(),
  isAdmin: boolean("is_admin").default(true),
  permissions: jsonb("permissions"),
  createdAt: timestamp("created_at").defaultNow(),
});

// Blog Posts
export const blogPosts = pgTable("blog_posts", {
  id: uuid("id").primaryKey().defaultRandom(),
  title: text("title").notNull(),
  slug: text("slug").unique().notNull(),
  content: text("content"),
  contentHtml: text("content_html"),
  excerpt: text("excerpt"),
  imageUrl: text("image_url"),
  published: boolean("published").default(false),
  publishedAt: timestamp("published_at"),
  authorId: uuid("author_id").references(() => users.id),
  tags: text("tags").array(),
  metaDescription: text("meta_description"),
  seoTitle: text("seo_title"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// CRM Clients
export const crmClients = pgTable("crm_clients", {
  id: uuid("id").primaryKey().defaultRandom(),
  firstName: text("first_name").notNull(),
  lastName: text("last_name").notNull(),
  clientId: text("client_id").unique(),
  email: text("email").notNull(),
  phone: text("phone"),
  address: text("address"),
  city: text("city"),
  state: text("state"),
  zip: text("zip"),
  country: text("country"),
  company: text("company"),
  notes: text("notes"),
  status: text("status").default("active"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// CRM Leads
export const crmLeads = pgTable("crm_leads", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  email: text("email").notNull(),
  phone: text("phone"),
  company: text("company"),
  message: text("message"),
  source: text("source"),
  status: text("status").default("new"),
  assignedTo: uuid("assigned_to").references(() => users.id),
  priority: text("priority").default("medium"),
  tags: text("tags").array(),
  followUpDate: date("follow_up_date"),
  value: decimal("value", { precision: 10, scale: 2 }),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// CRM Invoices
export const crmInvoices = pgTable("crm_invoices", {
  id: uuid("id").primaryKey().defaultRandom(),
  invoiceNumber: text("invoice_number").unique().notNull(),
  clientId: uuid("client_id").references(() => crmClients.id).notNull(),
  issueDate: date("issue_date").notNull(),
  dueDate: date("due_date").notNull(),
  subtotal: decimal("subtotal", { precision: 10, scale: 2 }).notNull(),
  taxAmount: decimal("tax_amount", { precision: 10, scale: 2 }).default("0"),
  total: decimal("total", { precision: 10, scale: 2 }).notNull(),
  status: text("status").default("draft"),
  notes: text("notes"),
  termsAndConditions: text("terms_and_conditions"),
  createdBy: uuid("created_by").references(() => users.id),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// CRM Invoice Items
export const crmInvoiceItems = pgTable("crm_invoice_items", {
  id: uuid("id").primaryKey().defaultRandom(),
  invoiceId: uuid("invoice_id").references(() => crmInvoices.id, { onDelete: "cascade" }).notNull(),
  description: text("description").notNull(),
  quantity: decimal("quantity", { precision: 10, scale: 2 }).default("1"),
  unitPrice: decimal("unit_price", { precision: 10, scale: 2 }).notNull(),
  taxRate: decimal("tax_rate", { precision: 5, scale: 2 }).default("0"),
  sortOrder: integer("sort_order").default(0),
  createdAt: timestamp("created_at").defaultNow(),
});

// Gallery Systems
export const galleries = pgTable("galleries", {
  id: uuid("id").primaryKey().defaultRandom(),
  title: text("title").notNull(),
  slug: text("slug").unique().notNull(),
  description: text("description"),
  coverImage: text("cover_image"),
  isPublic: boolean("is_public").default(true),
  isPasswordProtected: boolean("is_password_protected").default(false),
  password: text("password"),
  clientId: uuid("client_id").references(() => crmClients.id),
  createdBy: uuid("created_by").references(() => users.id),
  sortOrder: integer("sort_order").default(0),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const galleryImages = pgTable("gallery_images", {
  id: uuid("id").primaryKey().defaultRandom(),
  galleryId: uuid("gallery_id").references(() => galleries.id, { onDelete: "cascade" }).notNull(),
  filename: text("filename").notNull(),
  url: text("url").notNull(),
  title: text("title"),
  description: text("description"),
  sortOrder: integer("sort_order").default(0),
  metadata: jsonb("metadata"),
  createdAt: timestamp("created_at").defaultNow(),
});

// Calendar System
export const calendars = pgTable("calendars", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  description: text("description"),
  color: text("color").default("#3B82F6"),
  isDefault: boolean("is_default").default(false),
  isPublic: boolean("is_public").default(false),
  timezone: text("timezone").default("UTC"),
  ownerId: uuid("owner_id").references(() => users.id).notNull(),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const calendarCategories = pgTable("calendar_categories", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  description: text("description"),
  color: text("color").default("#3B82F6"),
  icon: text("icon"),
  createdBy: uuid("created_by").references(() => users.id).notNull(),
  createdAt: timestamp("created_at").defaultNow(),
});

export const calendarEvents = pgTable("calendar_events", {
  id: uuid("id").primaryKey().defaultRandom(),
  title: text("title").notNull(),
  description: text("description"),
  location: text("location"),
  startTime: timestamp("start_time").notNull(),
  endTime: timestamp("end_time").notNull(),
  allDay: boolean("all_day").default(false),
  timezone: text("timezone").default("UTC"),
  status: text("status").default("confirmed"),
  visibility: text("visibility").default("public"),
  importance: text("importance").default("normal"),
  categoryId: uuid("category_id").references(() => calendarCategories.id),
  calendarId: uuid("calendar_id").references(() => calendars.id, { onDelete: "cascade" }).notNull(),
  color: text("color").default("#3B82F6"),
  isRecurring: boolean("is_recurring").default(false),
  recurrenceRule: text("recurrence_rule"),
  recurrenceExceptionDates: text("recurrence_exception_dates").array(),
  parentEventId: uuid("parent_event_id"),
  createdBy: uuid("created_by").references(() => users.id).notNull(),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
  externalId: text("external_id"),
  externalSource: text("external_source"),
  icalUid: text("ical_uid"),
  isBookable: boolean("is_bookable").default(false),
  maxAttendees: integer("max_attendees"),
  bookingWindowStart: timestamp("booking_window_start"),
  bookingWindowEnd: timestamp("booking_window_end"),
});

export const eventAttendees = pgTable("event_attendees", {
  id: uuid("id").primaryKey().defaultRandom(),
  eventId: uuid("event_id").references(() => calendarEvents.id, { onDelete: "cascade" }).notNull(),
  email: text("email").notNull(),
  name: text("name"),
  role: text("role").default("attendee"),
  status: text("status").default("pending"),
  responseDate: timestamp("response_date"),
  notes: text("notes"),
  createdAt: timestamp("created_at").defaultNow(),
});

export const eventReminders = pgTable("event_reminders", {
  id: uuid("id").primaryKey().defaultRandom(),
  eventId: uuid("event_id").references(() => calendarEvents.id, { onDelete: "cascade" }).notNull(),
  type: text("type").default("email"),
  minutesBefore: integer("minutes_before").notNull(),
  sentAt: timestamp("sent_at"),
  createdAt: timestamp("created_at").defaultNow(),
});

// Messages/Email System
export const messages = pgTable("messages", {
  id: uuid("id").primaryKey().defaultRandom(),
  fromEmail: text("from_email").notNull(),
  toEmail: text("to_email").notNull(),
  subject: text("subject"),
  body: text("body"),
  threadId: uuid("thread_id"),
  createdAt: timestamp("created_at").defaultNow(),
});

// Newsletter System
export const newsletterSubscribers = pgTable("newsletter_subscribers", {
  id: uuid("id").primaryKey().defaultRandom(),
  email: text("email").unique().notNull(),
  firstName: text("first_name"),
  lastName: text("last_name"),
  status: text("status").default("active"),
  source: text("source"),
  tags: text("tags").array(),
  subscribedAt: timestamp("subscribed_at").defaultNow(),
  unsubscribedAt: timestamp("unsubscribed_at"),
});

// Stripe Integration
export const stripeCustomers = pgTable("stripe_customers", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").references(() => users.id),
  stripeCustomerId: text("stripe_customer_id").unique().notNull(),
  email: text("email").notNull(),
  name: text("name"),
  deletedAt: timestamp("deleted_at"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const stripeOrders = pgTable("stripe_orders", {
  id: uuid("id").primaryKey().defaultRandom(),
  stripeSessionId: text("stripe_session_id").unique().notNull(),
  customerId: uuid("customer_id").references(() => stripeCustomers.id),
  status: text("status").default("pending"),
  amountTotal: integer("amount_total").notNull(),
  currency: text("currency").default("usd"),
  productName: text("product_name"),
  voucherType: text("voucher_type"),
  metadata: jsonb("metadata"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Import Logs
export const importLogs = pgTable("import_logs", {
  id: uuid("id").primaryKey().defaultRandom(),
  filename: text("filename").notNull(),
  importedBy: uuid("imported_by").references(() => users.id),
  rowsProcessed: integer("rows_processed").default(0),
  rowsSuccess: integer("rows_success").default(0),
  rowsError: integer("rows_error").default(0),
  errorFileUrl: text("error_file_url"),
  createdAt: timestamp("created_at").defaultNow(),
});

// Insert schemas
export const insertUserSchema = createInsertSchema(users).pick({
  email: true,
  password: true,
  firstName: true,
  lastName: true,
});

export const insertBlogPostSchema = createInsertSchema(blogPosts).pick({
  title: true,
  slug: true,
  content: true,
  contentHtml: true,
  excerpt: true,
  imageUrl: true,
  published: true,
  tags: true,
  metaDescription: true,
  seoTitle: true,
});

export const insertCrmClientSchema = createInsertSchema(crmClients).pick({
  firstName: true,
  lastName: true,
  clientId: true,
  email: true,
  phone: true,
  address: true,
  city: true,
  state: true,
  zip: true,
  country: true,
  company: true,
  notes: true,
  status: true,
});

export const insertCrmLeadSchema = createInsertSchema(crmLeads).pick({
  name: true,
  email: true,
  phone: true,
  company: true,
  message: true,
  source: true,
  status: true,
  priority: true,
  tags: true,
  value: true,
});

export const insertCalendarEventSchema = createInsertSchema(calendarEvents).pick({
  title: true,
  description: true,
  location: true,
  startTime: true,
  endTime: true,
  allDay: true,
  timezone: true,
  status: true,
  visibility: true,
  importance: true,
  categoryId: true,
  calendarId: true,
  color: true,
  isRecurring: true,
  recurrenceRule: true,
  isBookable: true,
  maxAttendees: true,
});

export const insertGallerySchema = createInsertSchema(galleries).pick({
  title: true,
  slug: true,
  description: true,
  coverImage: true,
  isPublic: true,
  isPasswordProtected: true,
  password: true,
  clientId: true,
  sortOrder: true,
});

// Type exports
export type InsertUser = z.infer<typeof insertUserSchema>;
export type User = typeof users.$inferSelect;
export type BlogPost = typeof blogPosts.$inferSelect;
export type InsertBlogPost = z.infer<typeof insertBlogPostSchema>;
export type CrmClient = typeof crmClients.$inferSelect;
export type InsertCrmClient = z.infer<typeof insertCrmClientSchema>;
export type CrmLead = typeof crmLeads.$inferSelect;
export type InsertCrmLead = z.infer<typeof insertCrmLeadSchema>;
export type CalendarEvent = typeof calendarEvents.$inferSelect;
export type InsertCalendarEvent = z.infer<typeof insertCalendarEventSchema>;
export type Gallery = typeof galleries.$inferSelect;
export type InsertGallery = z.infer<typeof insertGallerySchema>;
