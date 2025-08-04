// Cloudflare Function to check IP blacklist
export async function onRequestPost(context) {
    const { request, env } = context;
    
    try {
        const { ip } = await request.json();
        
        // Check against Cloudflare's built-in threat intelligence
        const clientIP = request.headers.get('CF-Connecting-IP') || ip;
        const threatScore = request.cf?.botScore || 0;
        const country = request.cf?.country || 'Unknown';
        
        // Your custom blacklist logic
        let blocked = false;
        let source = 'none';
        
        // Check against stored blacklist (you'd upload your w/ folder data here)
        const blacklistData = await env.VISITOR_DATA.get('blacklist:ips');
        if (blacklistData) {
            const blacklist = JSON.parse(blacklistData);
            if (blacklist.includes(clientIP)) {
                blocked = true;
                source = 'custom_blacklist';
            }
        }
        
        // Check Cloudflare threat score (0-100, higher = more suspicious)
        if (threatScore > 30) {
            blocked = true;
            source = 'cloudflare_threat_score';
        }
        
        // Check for suspicious countries (optional)
        const highRiskCountries = ['CN', 'RU', 'KP']; // Add as needed
        if (highRiskCountries.includes(country)) {
            source = 'high_risk_country';
            // Don't auto-block, just flag
        }
        
        return Response.json({
            ip: clientIP,
            blocked: blocked,
            source: source,
            timestamp: new Date().toISOString(),
            security: {
                threatScore: threatScore,
                country: country,
                botScore: request.cf?.botScore,
                asn: request.cf?.asn,
                colo: request.cf?.colo
            }
        });
        
    } catch (error) {
        return Response.json({
            error: 'Failed to check blacklist',
            details: error.message
        }, { status: 500 });
    }
}
