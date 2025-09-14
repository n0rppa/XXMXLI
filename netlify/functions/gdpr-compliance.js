const fs = require('fs');
const path = require('path');

exports.handler = async function(event) {
  // Basic authentication via query parameter
  const SECRET_KEY = 'xxmxli_analytics_secure_2025_09_14';
  const providedKey = event.queryStringParameters?.key;
  
  if (providedKey !== SECRET_KEY) {
    return {
      statusCode: 401,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Unauthorized' })
    };
  }

  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Method not allowed' })
    };
  }

  try {
    const requestData = JSON.parse(event.body || '{}');
    const action = requestData.action;
    
    const analyticsDir = path.join(__dirname, '..', '..', 'data', 'analytics');
    
    if (!fs.existsSync(analyticsDir)) {
      return {
        statusCode: 200,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: 'No analytics data found' })
      };
    }
    
    if (action === 'delete_ip') {
      const ipToDelete = requestData.ip;
      if (!ipToDelete) {
        return {
          statusCode: 400,
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ error: 'IP address required' })
        };
      }
      
      // Process all analytics files
      const files = fs.readdirSync(analyticsDir)
        .filter(f => f.startsWith('analytics-') && f.endsWith('.jsonl'));
      
      let deletedEntries = 0;
      
      for (const file of files) {
        const filepath = path.join(analyticsDir, file);
        const content = fs.readFileSync(filepath, 'utf-8');
        const lines = content.trim().split('\n').filter(line => line.trim());
        
        const filteredLines = [];
        
        for (const line of lines) {
          try {
            const entry = JSON.parse(line);
            if (entry.ip !== ipToDelete) {
              filteredLines.push(line);
            } else {
              deletedEntries++;
            }
          } catch (e) {
            // Keep invalid JSON lines as-is
            filteredLines.push(line);
          }
        }
        
        // Write back the filtered content
        fs.writeFileSync(filepath, filteredLines.join('\n') + (filteredLines.length > 0 ? '\n' : ''));
      }
      
      return {
        statusCode: 200,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          message: `Deleted ${deletedEntries} entries for IP ${ipToDelete}`,
          deletedEntries: deletedEntries
        })
      };
    }
    
    if (action === 'delete_old') {
      const daysToKeep = requestData.days || 365; // Default 1 year
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);
      
      const files = fs.readdirSync(analyticsDir)
        .filter(f => f.startsWith('analytics-') && f.endsWith('.jsonl'));
      
      let deletedEntries = 0;
      
      for (const file of files) {
        const filepath = path.join(analyticsDir, file);
        const content = fs.readFileSync(filepath, 'utf-8');
        const lines = content.trim().split('\n').filter(line => line.trim());
        
        const filteredLines = [];
        
        for (const line of lines) {
          try {
            const entry = JSON.parse(line);
            const entryDate = new Date(entry.timestamp);
            
            if (entryDate >= cutoffDate) {
              filteredLines.push(line);
            } else {
              deletedEntries++;
            }
          } catch (e) {
            // Keep invalid JSON lines as-is
            filteredLines.push(line);
          }
        }
        
        // Write back the filtered content or delete empty files
        if (filteredLines.length > 0) {
          fs.writeFileSync(filepath, filteredLines.join('\n') + '\n');
        } else {
          fs.unlinkSync(filepath);
        }
      }
      
      return {
        statusCode: 200,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          message: `Deleted ${deletedEntries} entries older than ${daysToKeep} days`,
          deletedEntries: deletedEntries
        })
      };
    }
    
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Invalid action' })
    };
    
  } catch (error) {
    console.error('GDPR compliance error:', error);
    return {
      statusCode: 500,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Internal server error' })
    };
  }
};