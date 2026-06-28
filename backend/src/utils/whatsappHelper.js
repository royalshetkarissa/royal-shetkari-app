const env = require('../config/env');
const logger = require('./logger');

/**
 * Send an OTP via Meta WhatsApp Cloud API.
 * Uses native fetch.
 * 
 * @param {string} mobile Target mobile number (with country code if required)
 * @param {string} otp The OTP to send
 * @returns {Promise<boolean>} True if successful, false otherwise
 */
async function sendWhatsAppOtp(mobile, otp) {
  // If no token or phone ID is provided, and we are in dev, just skip
  if (!env.META_WHATSAPP.TOKEN || !env.META_WHATSAPP.PHONE_ID) {
    if (env.NODE_ENV === 'development') {
      logger.info('Skipping WhatsApp OTP send in development mode due to missing credentials');
      return true;
    }
    logger.error('META_WHATSAPP_TOKEN and META_PHONE_ID are missing in production');
    return false;
  }

  // Ensure mobile has country code (assuming India +91 for Royal Shetkari)
  let targetMobile = mobile;
  if (!targetMobile.startsWith('91') && targetMobile.length === 10) {
    targetMobile = '91' + targetMobile;
  }

  try {
    const response = await fetch(
      `https://graph.facebook.com/v17.0/${env.META_WHATSAPP.PHONE_ID}/messages`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${env.META_WHATSAPP.TOKEN}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          messaging_product: 'whatsapp',
          to: targetMobile,
          type: 'template',
          template: {
            name: 'royal_shetkari_otp', // Replace with approved template name
            language: {
              code: 'en' // or 'mr' / 'hi' based on preference
            },
            components: [
              {
                type: 'body',
                parameters: [
                  {
                    type: 'text',
                    text: otp
                  }
                ]
              },
              {
                type: 'button',
                sub_type: 'url',
                index: '0',
                parameters: [
                  {
                    type: 'text',
                    text: otp
                  }
                ]
              }
            ]
          }
        }),
      }
    );

    const result = await response.json();

    if (!response.ok) {
      logger.error('Failed to send WhatsApp OTP:', { result });
      return false;
    }

    logger.info(`WhatsApp OTP sent successfully to ${mobile}`);
    return true;
  } catch (err) {
    logger.error('Error sending WhatsApp OTP:', { error: err.message });
    return false;
  }
}

module.exports = {
  sendWhatsAppOtp,
};
