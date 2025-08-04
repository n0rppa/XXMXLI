// Cloudflare Function to replace visitor-logger.php
export async function onRequestPost(context) {
    const { request, env } = context;
    
    try {
        // Get visitor data from request
        const visitorData = await request.json();
        
        // Add server-side data
        const clientIP = request.headers.get('CF-Connecting-IP') || 
                        request.headers.get('X-Forwarded-For') || 
                        'Unknown';
        
        const enhancedData = {
            ...visitorData,
            serverIP: clientIP,
            serverTime: new Date().toISOString(),
            cfCountry: request.cf?.country || 'Unknown',
            cfCity: request.cf?.city || 'Unknown',
            userAgent: request.headers.get('User-Agent') || 'Unknown'
        };
        
        // Store in Cloudflare KV (key-value storage)
        const sessionKey = `visitor:${enhancedData.sessionId}`;
        await env.VISITOR_DATA.put(sessionKey, JSON.stringify(enhancedData));
        
        // Update daily stats
        const today = new Date().toISOString().split('T')[0];
        const statsKey = `stats:${today}`;
        
        let dailyStats = await env.VISITOR_DATA.get(statsKey);
        dailyStats = dailyStats ? JSON.parse(dailyStats) : { visits: 0, uniqueIPs: new Set() };
        
        dailyStats.visits++;
        dailyStats.uniqueIPs.add(clientIP);
        
        await env.VISITOR_DATA.put(statsKey, JSON.stringify({
            ...dailyStats,
            uniqueIPs: Array.from(dailyStats.uniqueIPs)
        }));
        
        return Response.json({
            success: true,
            message: 'Visitor logged successfully',
            sessionId: enhancedData.sessionId,
            serverTime: enhancedData.serverTime,
            cfData: {
                country: request.cf?.country,
                city: request.cf?.city,
                ip: clientIP
            }
        });
        
    } catch (error) {
        return Response.json({
            error: 'Failed to log visitor',
            details: error.message
        }, { status: 500 });
    }
}
