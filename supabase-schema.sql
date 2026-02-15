-- MindShelf Supabase Database Schema
-- Run this SQL in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    notifications_enabled BOOLEAN DEFAULT true,
    reminder_time TIME DEFAULT '09:00:00',
    is_premium BOOLEAN DEFAULT false,
    premium_until TIMESTAMPTZ,
    premium_purchase_date TIMESTAMPTZ,
    language_code TEXT DEFAULT 'en'
);

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Users can only read and update their own data
CREATE POLICY "Users can view own data" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own data" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Bookmarks table
CREATE TABLE public.bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    url TEXT NOT NULL,
    notes TEXT DEFAULT '',
    category TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',
    is_read BOOLEAN DEFAULT false,
    thumbnail_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;

-- Users can only manage their own bookmarks
CREATE POLICY "Users can view own bookmarks" ON public.bookmarks
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own bookmarks" ON public.bookmarks
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own bookmarks" ON public.bookmarks
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own bookmarks" ON public.bookmarks
    FOR DELETE USING (auth.uid() = user_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookmarks_updated_at BEFORE UPDATE ON public.bookmarks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Indexes for better performance
CREATE INDEX idx_bookmarks_user_id ON public.bookmarks(user_id);
CREATE INDEX idx_bookmarks_category ON public.bookmarks(category);
CREATE INDEX idx_bookmarks_created_at ON public.bookmarks(created_at DESC);
CREATE INDEX idx_bookmarks_is_read ON public.bookmarks(is_read);

-- Function to create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create user profile
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Users can delete their own account
CREATE POLICY "Users can delete own data" ON public.users
    FOR DELETE USING (auth.uid() = id);

-- RPC function: fully delete the current user (profile + bookmarks cascade + auth record)
CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void AS $$
BEGIN
    -- Delete profile (bookmarks cascade automatically via FK)
    DELETE FROM public.users WHERE id = auth.uid();
    -- Delete auth record
    DELETE FROM auth.users WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Sample categories for reference
-- x (twitter), instagram, youtube, article, video, general
