// Cloudflare Function to get visitor statistics
export async function onRequestGet(context) {
    const { request, env } = context;
    
    try {
        const url = new URL(request.url);
        const action = url.searchParams.get('action') || 'overview';
        const limit = Math.min(parseInt(url.searchParams.get('limit')) || 100, 1000);
        
        switch (action) {
            case 'overview':
                return await getOverviewStats(env);
                
            case 'visitors':
                return await getRecentVisitors(env, limit);
                
            case 'daily':
                return await getDailyStats(env);
                
            default:
                return Response.json({ error: 'Invalid action' }, { status: 400 });
        }
        
    } catch (error) {
        return Response.json({
            error: 'Failed to get statistics',
            details: error.message
        }, { status: 500 });
    }
}

async function getOverviewStats(env) {
    // Get today's stats
    const today = new Date().toISOString().split('T')[0];
    const todayStats = await env.VISITOR_DATA.get(`stats:${today}`);
    const parsed = todayStats ? JSON.parse(todayStats) : { visits: 0, uniqueIPs: [] };
    
    // Get yesterday's stats for comparison
    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const yesterdayStats = await env.VISITOR_DATA.get(`stats:${yesterday}`);
    const yesterdayParsed = yesterdayStats ? JSON.parse(yesterdayStats) : { visits: 0, uniqueIPs: [] };
    
    return Response.json({
        overview: {
            totalVisitors: parsed.visits,
            uniqueIPs: parsed.uniqueIPs.length,
            blockedVisitors: 0, // Would need to track this separately
            botVisitors: 0
        },
        timeframe: {
            today: parsed.visits,
            yesterday: yesterdayParsed.visits,
            last24h: parsed.visits
        }
    });
}

async function getRecentVisitors(env, limit) {
    // In a real implementation, you'd iterate through KV keys
    // For now, return sample structure
    return Response.json({
        visitors: [],
        total: 0,
        limit: limit,
        message: 'Visitor data stored in Cloudflare KV - implement key iteration'
    });
}

async function getDailyStats(env) {
    const stats = {};
    const days = 7;
    
    for (let i = 0; i < days; i++) {
        const date = new Date(Date.now() - i * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
        const dayStats = await env.VISITOR_DATA.get(`stats:${date}`);
        
        if (dayStats) {
            stats[date] = JSON.parse(dayStats);
        }
    }
    
    return Response.json(stats);
}
