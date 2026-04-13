-- Create site_settings table for admin-managed contact details, UPI ID, etc.
CREATE TABLE IF NOT EXISTS site_settings (
  key   VARCHAR(100) PRIMARY KEY,
  value TEXT NOT NULL
);

-- Insert default settings
INSERT INTO site_settings (key, value) VALUES
  ('support_email', 'support@visionfurnish.com'),
  ('support_phone', '+91 9876543210'),
  ('support_chat_url', ''),
  ('upi_id', ''),
  ('privacy_policy', 'Your privacy is important to us. We collect only the information necessary to provide our services. Your personal data is encrypted and stored securely. We do not share your information with third parties without your consent.'),
  ('terms_of_service', 'By using VisionFurnish, you agree to our terms of service. All purchases are subject to our return and refund policy.')
ON CONFLICT (key) DO NOTHING;

-- Also add 'packed' to order_status enum if not already there
DO $$ BEGIN
  ALTER TYPE order_status ADD VALUE IF NOT EXISTS 'packed' AFTER 'processing';
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
