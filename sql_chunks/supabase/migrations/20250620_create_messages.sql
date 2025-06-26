-- Migration: Create messages table
CREATE TABLE public.messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  from_email text NOT NULL,
  to_email text NOT NULL,
  subject text,
  body text,
  thread_id uuid,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Messages are viewable by owner" ON public.messages
  FOR SELECT USING ( auth.uid() = user_id );

CREATE POLICY "Messages are insertable by owner" ON public.messages
  FOR INSERT WITH CHECK ( auth.uid() = user_id );
