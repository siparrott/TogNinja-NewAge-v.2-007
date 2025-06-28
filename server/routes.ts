import type { Express, Request, Response } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { 
  insertUserSchema,
  insertBlogPostSchema,
  insertCrmClientSchema,
  insertCrmLeadSchema,
  insertCalendarEventSchema,
  insertGallerySchema
} from "@shared/schema";
import { z } from "zod";

// Authentication middleware placeholder - replace with actual auth
const authenticateUser = async (req: Request, res: Response, next: Function) => {
  // For now, skip authentication and set a default user
  // In production, validate JWT token and get user from database
  req.user = { id: "default-user-id", email: "admin@example.com", isAdmin: true };
  next();
};

export async function registerRoutes(app: Express): Promise<Server> {
  
  // ==================== USER ROUTES ====================
  app.get("/api/users/:id", authenticateUser, async (req: Request, res: Response) => {
    try {
      const user = await storage.getUser(req.params.id);
      if (!user) {
        return res.status(404).json({ error: "User not found" });
      }
      res.json(user);
    } catch (error) {
      console.error("Error fetching user:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.post("/api/users", async (req: Request, res: Response) => {
    try {
      const userData = insertUserSchema.parse(req.body);
      const user = await storage.createUser(userData);
      res.status(201).json(user);
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({ error: "Validation error", details: error.errors });
      }
      console.error("Error creating user:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  // ==================== BLOG ROUTES ====================
  app.get("/api/blog/posts", async (req: Request, res: Response) => {
    try {
      const published = req.query.published === 'true' ? true : req.query.published === 'false' ? false : undefined;
      const posts = await storage.getBlogPosts(published);
      res.json({ posts, count: posts.length });
    } catch (error) {
      console.error("Error fetching blog posts:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.get("/api/blog/posts/:slug", async (req: Request, res: Response) => {
    try {
      const post = await storage.getBlogPostBySlug(req.params.slug);
      if (!post) {
        return res.status(404).json({ error: "Post not found" });
      }
      res.json(post);
    } catch (error) {
      console.error("Error fetching blog post:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.post("/api/blog/posts", authenticateUser, async (req: Request, res: Response) => {
    try {
      const postData = { ...req.body, authorId: req.user.id };
      const validatedData = insertBlogPostSchema.parse(postData);
      const post = await storage.createBlogPost(validatedData);
      res.status(201).json(post);
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({ error: "Validation error", details: error.errors });
      }
      console.error("Error creating blog post:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.put("/api/blog/posts/:id", authenticateUser, async (req: Request, res: Response) => {
    try {
      const post = await storage.updateBlogPost(req.params.id, req.body);
      res.json(post);
    } catch (error) {
      console.error("Error updating blog post:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.delete("/api/blog/posts/:id", authenticateUser, async (req: Request, res: Response) => {
    try {
      await storage.deleteBlogPost(req.params.id);
      res.json({ success: true });
    } catch (error) {
      console.error("Error deleting blog post:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  // ==================== CRM CLIENT ROUTES ====================
  app.get("/api/crm/clients", authenticateUser, async (req: Request, res: Response) => {
    try {
      const clients = await storage.getCrmClients();
      res.json(clients);
    } catch (error) {
      console.error("Error fetching CRM clients:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.get("/api/crm/clients/:id", authenticateUser, async (req: Request, res: Response) => {
    try {
      const client = await storage.getCrmClient(req.params.id);
      if (!client) {
        return res.status(404).json({ error: "Client not found" });
      }
      res.json(client);
    } catch (error) {
      console.error("Error fetching CRM client:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.post("/api/crm/clients", authenticateUser, async (req: Request, res: Response) => {
    try {
      const clientData = insertCrmClientSchema.parse(req.body);
      const client = await storage.createCrmClient(clientData);
      res.status(201).json(client);
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({ error: "Validation error", details: error.errors });
      }
      console.error("Error creating CRM client:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.put("/api/crm/clients/:id", authenticateUser, async (req: Request, res: Response) => {
    try {
      const client = await storage.updateCrmClient(req.params.id, req.body);
      res.json(client);
    } catch (error) {
      console.error("Error updating CRM client:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.delete("/api/crm/clients/:id", authenticateUser, async (req: Request, res: Response) => {
    try {
      await storage.deleteCrmClient(req.params.id);
      res.json({ success: true });
    } catch (error) {
      console.error("Error deleting CRM client:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  // ==================== CRM LEAD ROUTES ====================
  app.get("/api/crm/leads", authenticateUser, async (req: Request, res: Response) => {
    try {
      const status = req.query.status as string;
      const leads = await storage.getCrmLeads(status);
      res.json(leads);
    } catch (error) {
      console.error("Error fetching CRM leads:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.get("/api/crm/leads/:id", authenticateUser, async (req: Request, res: Response) => {
    try {
      const lead = await storage.getCrmLead(req.params.id);
      if (!lead) {
        return res.status(404).json({ error: "Lead not found" });
      }
      res.json(lead);
    } catch (error) {
      console.error("Error fetching CRM lead:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.post("/api/crm/leads", authenticateUser, async (req: Request, res: Response) => {
    try {
      const leadData = insertCrmLeadSchema.parse(req.body);
      const lead = await storage.createCrmLead(leadData);
      res.status(201).json(lead);
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({ error: "Validation error", details: error.errors });
      }
      console.error("Error creating CRM lead:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.put("/api/crm/leads/:id", authenticateUser, async (req: Request, res: Response) => {
    try {
      const lead = await storage.updateCrmLead(req.params.id, req.body);
      res.json(lead);
    } catch (error) {
      console.error("Error updating CRM lead:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.delete("/api/crm/leads/:id", authenticateUser, async (req: Request, res: Response) => {
    try {
      await storage.deleteCrmLead(req.params.id);
      res.json({ success: true });
    } catch (error) {
      console.error("Error deleting CRM lead:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  // ==================== CALENDAR ROUTES ====================
  app.get("/api/calendar/events", authenticateUser, async (req: Request, res: Response) => {
    try {
      const calendarId = req.query.calendarId as string;
      const events = await storage.getCalendarEvents(calendarId);
      res.json(events);
    } catch (error) {
      console.error("Error fetching calendar events:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.get("/api/calendar/events/:id", authenticateUser, async (req: Request, res: Response) => {
    try {
      const event = await storage.getCalendarEvent(req.params.id);
      if (!event) {
        return res.status(404).json({ error: "Event not found" });
      }
      res.json(event);
    } catch (error) {
      console.error("Error fetching calendar event:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.post("/api/calendar/events", authenticateUser, async (req: Request, res: Response) => {
    try {
      const eventData = { ...req.body, createdBy: req.user.id };
      const validatedData = insertCalendarEventSchema.parse(eventData);
      const event = await storage.createCalendarEvent(validatedData);
      res.status(201).json(event);
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({ error: "Validation error", details: error.errors });
      }
      console.error("Error creating calendar event:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.put("/api/calendar/events/:id", authenticateUser, async (req: Request, res: Response) => {
    try {
      const event = await storage.updateCalendarEvent(req.params.id, req.body);
      res.json(event);
    } catch (error) {
      console.error("Error updating calendar event:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.delete("/api/calendar/events/:id", authenticateUser, async (req: Request, res: Response) => {
    try {
      await storage.deleteCalendarEvent(req.params.id);
      res.json({ success: true });
    } catch (error) {
      console.error("Error deleting calendar event:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  // ==================== GALLERY ROUTES ====================
  app.get("/api/galleries", async (req: Request, res: Response) => {
    try {
      const galleries = await storage.getGalleries();
      res.json(galleries);
    } catch (error) {
      console.error("Error fetching galleries:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.get("/api/galleries/:slug", async (req: Request, res: Response) => {
    try {
      const gallery = await storage.getGalleryBySlug(req.params.slug);
      if (!gallery) {
        return res.status(404).json({ error: "Gallery not found" });
      }
      res.json(gallery);
    } catch (error) {
      console.error("Error fetching gallery:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.post("/api/galleries", authenticateUser, async (req: Request, res: Response) => {
    try {
      const galleryData = { ...req.body, createdBy: req.user.id };
      const validatedData = insertGallerySchema.parse(galleryData);
      const gallery = await storage.createGallery(validatedData);
      res.status(201).json(gallery);
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({ error: "Validation error", details: error.errors });
      }
      console.error("Error creating gallery:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.put("/api/galleries/:id", authenticateUser, async (req: Request, res: Response) => {
    try {
      const gallery = await storage.updateGallery(req.params.id, req.body);
      res.json(gallery);
    } catch (error) {
      console.error("Error updating gallery:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.delete("/api/galleries/:id", authenticateUser, async (req: Request, res: Response) => {
    try {
      await storage.deleteGallery(req.params.id);
      res.json({ success: true });
    } catch (error) {
      console.error("Error deleting gallery:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  // ==================== DASHBOARD METRICS ROUTE ====================
  app.get("/api/crm/dashboard/metrics", authenticateUser, async (req: Request, res: Response) => {
    try {
      // Mock dashboard metrics - replace with actual calculations
      const metrics = {
        avgOrderValue: 150.00,
        activeUsers: 25,
        bookedRevenue: 5250.00,
        trendData: [
          { date: "2025-06-22", value: 750 },
          { date: "2025-06-23", value: 920 },
          { date: "2025-06-24", value: 1100 },
          { date: "2025-06-25", value: 880 },
          { date: "2025-06-26", value: 1200 },
          { date: "2025-06-27", value: 950 },
          { date: "2025-06-28", value: 1250 }
        ]
      };
      res.json(metrics);
    } catch (error) {
      console.error("Error fetching dashboard metrics:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  // ==================== HEALTH CHECK ====================
  app.get("/api/health", (req: Request, res: Response) => {
    res.json({ status: "ok", timestamp: new Date().toISOString() });
  });

  const httpServer = createServer(app);
  return httpServer;
}

// Extend Request interface to include user
declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        email: string;
        isAdmin: boolean;
      };
    }
  }
}
