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
    // Basic guard: limit payload size
    if ((event.body || '').length > 64 * 1024) {
      return { statusCode: 413, headers: CORS_HEADERS, body: 'Payload too large' };
    }
    
    // Normalize payload
    const kind = (requestData.kind || 'pageview').toLowerCase();
    const entryBase = {
      ts: new Date().toISOString(),
      kind,
      ip: clientIP,
      userAgent,
      referer,
      page: requestData.page || '',
      path: requestData.path || '',
      country: event.headers['cf-ipcountry'] || '',
      sessionId: requestData.sessionId || ''
    };
    let analyticsEntry;
    if (kind === 'event') {
      analyticsEntry = {
        ...entryBase,
        name: String(requestData.name || '').slice(0,64),
        data: requestData.data || {},
        visibility: requestData.visibility || ''
      };
    } else {
      analyticsEntry = {
        ...entryBase,
        referrer: requestData.referrer || '',
        device: requestData.device || null
      };
    }
    
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