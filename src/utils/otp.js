/**
 * Simple in-memory OTP store for Forgot-Password flow.
 *
 * In production, replace with Redis or a database-backed store.
 */

const otpStore = new Map(); // key: email, value: { otp, expiresAt }

/**
 * Generate a 6-digit OTP and store it with an expiry.
 */
const generateOTP = (email) => {
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expiryMinutes = parseInt(process.env.OTP_EXPIRY_MINUTES, 10) || 10;
  const expiresAt = Date.now() + expiryMinutes * 60 * 1000;

  otpStore.set(email, { otp, expiresAt });

  return otp;
};

/**
 * Verify the OTP for a given email.
 * Returns true if valid, false otherwise.
 */
const verifyOTP = (email, otp) => {
  const record = otpStore.get(email);
  if (!record) return false;

  if (Date.now() > record.expiresAt) {
    otpStore.delete(email);
    return false;
  }

  if (record.otp !== otp) return false;

  // OTP is single-use — delete after successful verification
  otpStore.delete(email);
  return true;
};

module.exports = { generateOTP, verifyOTP };
