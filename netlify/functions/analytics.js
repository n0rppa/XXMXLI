const fs = require('fs');
const path = require('path');

exports.handler = async function(event) {
  // CORS headers
  const CORS_HEADERS = { 
    'Access-Control-Allow-Origin': '*', 
    'Access-Control-Allow-Methods': 'POST, OPTIONS', 
    'Access-Control-Allow-Headers': 'Content-Type' 
  };
  
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 204, headers: CORS_HEADERS, body: '' };
  }
  
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, headers: CORS_HEADERS, body: 'Method not allowed' };
  }

  try {
    // Extract visitor data
    const clientIP = event.headers['x-forwarded-for'] || 
                    event.headers['x-real-ip'] || 
                    event.clientContext?.ip || 
                    'unknown';
    
    const userAgent = event.headers['user-agent'] || 'unknown';
    const referer = event.headers['referer'] || event.headers['referrer'] || '';
    
    // Parse request body
    let requestData = {};
    try {
      requestData = JSON.parse(event.body || '{}');
    } catch (e) {
      requestData = {};
    }
    
    // Create analytics entry
    const analyticsEntry = {
      timestamp: new Date().toISOString(),
      ip: clientIP,
      userAgent: userAgent,
      referer: referer,
      page: requestData.page || '',
      country: event.headers['cf-ipcountry'] || '', // Cloudflare country header if available
      sessionId: requestData.sessionId || '',
      viewport: requestData.viewport || '',
      language: requestData.language || '',
      platform: requestData.platform || ''
    };
    
    // Store analytics data
    const analyticsDir = path.join(__dirname, '..', '..', 'data', 'analytics');
    if (!fs.existsSync(analyticsDir)) {
      fs.mkdirSync(analyticsDir, { recursive: true });
    }
    
    // Store by date for easier management
    const dateStr = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
    const filename = `analytics-${dateStr}.jsonl`;
    const filepath = path.join(analyticsDir, filename);
    
    // Append to daily log file (JSONL format - one JSON object per line)
    const logEntry = JSON.stringify(analyticsEntry) + '\n';
    fs.appendFileSync(filepath, logEntry);
    
    return {
      statusCode: 200,
      headers: CORS_HEADERS,
      body: JSON.stringify({ status: 'logged' })
    };
    
  } catch (error) {
    console.error('Analytics error:', error);
    return {
      statusCode: 500,
      headers: CORS_HEADERS,
      body: JSON.stringify({ error: 'Internal server error' })
    };
  }
};