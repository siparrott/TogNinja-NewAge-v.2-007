-- Migration: Create invoices table
CREATE TABLE public.invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id uuid REFERENCES public.clients(id) ON DELETE SET NULL,
  amount numeric(10,2) NOT NULL,
  status text DEFAULT 'draft',
  pdf_url text,
  created_at timestamptz DEFAULT now()
);

-- Row‑Level Security: only owner can see their invoices
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Invoices are viewable by owner" ON public.invoices
  FOR SELECT USING ( auth.uid() = user_id );

CREATE POLICY "Invoices are insertable by owner" ON public.invoices
  FOR INSERT WITH CHECK ( auth.uid() = user_id );

CREATE POLICY "Invoices are updatable by owner" ON public.invoices
  FOR UPDATE USING ( auth.uid() = user_id );
