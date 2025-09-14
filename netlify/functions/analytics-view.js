const fs = require('fs');
const path = require('path');

exports.handler = async function(event) {
  // Basic authentication via query parameter (CHANGE THIS SECRET IN PRODUCTION!)
  const SECRET_KEY = 'xxmxli_analytics_secure_2025_09_14';
  const providedKey = event.queryStringParameters?.key;
  
  if (providedKey !== SECRET_KEY) {
    return {
      statusCode: 401,
      body: JSON.stringify({ error: 'Unauthorized' })
    };
  }

  try {
    const analyticsDir = path.join(__dirname, '..', '..', 'data', 'analytics');
    
    if (!fs.existsSync(analyticsDir)) {
      return {
        statusCode: 200,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify([])
      };
    }
    
    // Read all analytics files
    const files = fs.readdirSync(analyticsDir)
      .filter(f => f.startsWith('analytics-') && f.endsWith('.jsonl'))
      .sort()
      .reverse(); // Most recent first
    
    let allEntries = [];
    
    // Read recent files (last 30 days worth)
    const recentFiles = files.slice(0, 30);
    
    for (const file of recentFiles) {
      const filepath = path.join(analyticsDir, file);
      const content = fs.readFileSync(filepath, 'utf-8');
      const lines = content.trim().split('\n').filter(line => line.trim());
      
      for (const line of lines) {
        try {
          const entry = JSON.parse(line);
          allEntries.push(entry);
        } catch (e) {
          // Skip invalid JSON lines
          continue;
        }
      }
    }
    
    // Sort by timestamp (most recent first)
    allEntries.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    
    return {
      statusCode: 200,
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify(allEntries)
    };
    
  } catch (error) {
    console.error('Analytics view error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Internal server error' })
    };
  }
};