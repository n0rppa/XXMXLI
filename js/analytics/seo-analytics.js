/**
 * XXMXLI SEO Analytics Module
 * Search engine traffic analysis, keyword tracking, meta optimization
 */

class SeoAnalyticsModule {
    constructor(core) {
        this.core = core;
        this.config = {
            trackSearchEngines: true,
            trackKeywords: true,
            trackMetaTags: true,
            trackBacklinks: false, // Requires external API
            searchEngines: {
                'google': /google\./i,
                'bing': /bing\./i,
                'yahoo': /yahoo\./i,
                'duckduckgo': /duckduckgo\./i,
                'yandex': /yandex\./i,
                'baidu': /baidu\./i
            }
        };
        
        this.pageMetadata = {};
        this.searchData = {};
        this.socialShares = {};
    }

    async init() {
        this.analyzeCurrentPage();
        this.detectSearchTraffic();
        this.trackSocialShares();
        this.bindEvents();
        
        if (this.core.config.debug) {
            console.log('🔍 SEO Analytics module initialized');
        }
    }

    analyzeCurrentPage() {
        this.pageMetadata = {
            url: window.location.href,
            title: document.title,
            description: this.getMetaContent('description'),
            keywords: this.getMetaContent('keywords'),
            canonical: this.getCanonicalUrl(),
            openGraph: this.getOpenGraphData(),
            twitterCard: this.getTwitterCardData(),
            schemaMarkup: this.getSchemaMarkup(),
            headings: this.getHeadingStructure(),
            internalLinks: this.getInternalLinks(),
            externalLinks: this.getExternalLinks(),
            images: this.getImageAnalysis(),
            pagespeed: this.estimatePageSpeed(),
            mobileOptimized: this.checkMobileOptimization(),
            timestamp: new Date().toISOString()
        };

        // Send page metadata for analysis
        this.core.sendEvent('seo_event', {
            type: 'page_analysis',
            metadata: this.pageMetadata
        });
    }

    getMetaContent(name) {
        const meta = document.querySelector(`meta[name="${name}"]`) || 
                     document.querySelector(`meta[property="${name}"]`);
        return meta ? meta.getAttribute('content') : null;
    }

    getCanonicalUrl() {
        const canonical = document.querySelector('link[rel="canonical"]');
        return canonical ? canonical.href : null;
    }

    getOpenGraphData() {
        const ogTags = document.querySelectorAll('meta[property^="og:"]');
        const ogData = {};
        
        ogTags.forEach(tag => {
            const property = tag.getAttribute('property').replace('og:', '');
            ogData[property] = tag.getAttribute('content');
        });
        
        return ogData;
    }

    getTwitterCardData() {
        const twitterTags = document.querySelectorAll('meta[name^="twitter:"]');
        const twitterData = {};
        
        twitterTags.forEach(tag => {
            const name = tag.getAttribute('name').replace('twitter:', '');
            twitterData[name] = tag.getAttribute('content');
        });
        
        return twitterData;
    }

    getSchemaMarkup() {
        const schemaScripts = document.querySelectorAll('script[type="application/ld+json"]');
        const schemas = [];
        
        schemaScripts.forEach(script => {
            try {
                const data = JSON.parse(script.textContent);
                schemas.push(data);
            } catch (e) {
                // Invalid JSON schema
            }
        });
        
        return schemas;
    }

    getHeadingStructure() {
        const headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
        const structure = [];
        
        headings.forEach((heading, index) => {
            structure.push({
                level: parseInt(heading.tagName.charAt(1)),
                text: heading.textContent.trim(),
                id: heading.id || null,
                index: index
            });
        });
        
        return structure;
    }

    getInternalLinks() {
        const hostname = window.location.hostname;
        const links = document.querySelectorAll('a[href]');
        const internalLinks = [];
        
        links.forEach(link => {
            const href = link.href;
            if (href.includes(hostname) || href.startsWith('/')) {
                internalLinks.push({
                    href: href,
                    text: link.textContent.trim(),
                    title: link.title || null,
                    rel: link.rel || null
                });
            }
        });
        
        return internalLinks;
    }

    getExternalLinks() {
        const hostname = window.location.hostname;
        const links = document.querySelectorAll('a[href]');
        const externalLinks = [];
        
        links.forEach(link => {
            const href = link.href;
            if (href.startsWith('http') && !href.includes(hostname)) {
                externalLinks.push({
                    href: href,
                    text: link.textContent.trim(),
                    domain: new URL(href).hostname,
                    rel: link.rel || null,
                    target: link.target || null
                });
            }
        });
        
        return externalLinks;
    }

    getImageAnalysis() {
        const images = document.querySelectorAll('img');
        const imageData = {
            total: images.length,
            withAlt: 0,
            withTitle: 0,
            withoutAlt: 0,
            details: []
        };
        
        images.forEach(img => {
            const hasAlt = !!img.alt;
            const hasTitle = !!img.title;
            
            if (hasAlt) imageData.withAlt++;
            if (hasTitle) imageData.withTitle++;
            if (!hasAlt) imageData.withoutAlt++;
            
            imageData.details.push({
                src: img.src,
                alt: img.alt || null,
                title: img.title || null,
                width: img.naturalWidth || img.width,
                height: img.naturalHeight || img.height,
                hasAlt: hasAlt,
                hasTitle: hasTitle
            });
        });
        
        return imageData;
    }

    estimatePageSpeed() {
        if (performance.timing) {
            const timing = performance.timing;
            return {
                loadTime: timing.loadEventEnd - timing.navigationStart,
                domReady: timing.domContentLoadedEventEnd - timing.navigationStart,
                firstByte: timing.responseStart - timing.navigationStart
            };
        }
        return null;
    }

    checkMobileOptimization() {
        const viewport = document.querySelector('meta[name="viewport"]');
        const hasViewport = !!viewport;
        
        return {
            hasViewportMeta: hasViewport,
            viewportContent: viewport ? viewport.content : null,
            isResponsive: this.detectResponsiveDesign()
        };
    }

    detectResponsiveDesign() {
        // Simple responsive design detection
        const stylesheets = document.querySelectorAll('link[rel="stylesheet"]');
        let hasMediaQueries = false;
        
        stylesheets.forEach(stylesheet => {
            if (stylesheet.media && stylesheet.media !== 'all') {
                hasMediaQueries = true;
            }
        });
        
        // Check for common responsive framework classes
        const responsiveClasses = ['container', 'row', 'col-', 'grid', 'flex'];
        const hasResponsiveClasses = responsiveClasses.some(className => 
            document.querySelector(`[class*="${className}"]`)
        );
        
        return hasMediaQueries || hasResponsiveClasses;
    }

    detectSearchTraffic() {
        const referrer = document.referrer;
        if (!referrer) return;

        const searchEngine = this.identifySearchEngine(referrer);
        if (searchEngine) {
            const keywords = this.extractKeywords(referrer);
            
            this.searchData = {
                searchEngine: searchEngine,
                referrer: referrer,
                keywords: keywords,
                landingPage: window.location.href,
                timestamp: new Date().toISOString()
            };

            // Send search traffic data
            this.core.sendEvent('seo_event', {
                type: 'search_traffic',
                searchData: this.searchData
            });

            if (this.core.config.debug) {
                console.log('🔍 Search traffic detected:', this.searchData);
            }
        }
    }

    identifySearchEngine(referrer) {
        for (const [engine, pattern] of Object.entries(this.config.searchEngines)) {
            if (pattern.test(referrer)) {
                return engine;
            }
        }
        return null;
    }

    extractKeywords(referrer) {
        try {
            const url = new URL(referrer);
            const params = url.searchParams;
            
            // Common search parameter names
            const searchParams = ['q', 'query', 'search', 'p', 'wd'];
            
            for (const param of searchParams) {
                const value = params.get(param);
                if (value) {
                    return decodeURIComponent(value);
                }
            }
        } catch (e) {
            // Invalid URL
        }
        
        return null;
    }

    trackSocialShares() {
        // Track social sharing buttons and interactions
        const socialButtons = document.querySelectorAll('[data-social], .social-share, .share-button');
        
        socialButtons.forEach(button => {
            button.addEventListener('click', (e) => {
                const platform = this.identifySocialPlatform(button);
                if (platform) {
                    this.core.sendEvent('seo_event', {
                        type: 'social_share',
                        platform: platform,
                        url: window.location.href,
                        title: document.title
                    });
                }
            });
        });

        // Detect social media referrals
        const referrer = document.referrer;
        if (referrer) {
            const socialPlatform = this.identifySocialReferrer(referrer);
            if (socialPlatform) {
                this.core.sendEvent('seo_event', {
                    type: 'social_referral',
                    platform: socialPlatform,
                    referrer: referrer,
                    landingPage: window.location.href
                });
            }
        }
    }

    identifySocialPlatform(element) {
        const href = element.href || '';
        const className = element.className || '';
        const dataAttrs = element.dataset;
        
        if (href.includes('facebook.com') || className.includes('facebook') || dataAttrs.social === 'facebook') {
            return 'facebook';
        }
        if (href.includes('twitter.com') || className.includes('twitter') || dataAttrs.social === 'twitter') {
            return 'twitter';
        }
        if (href.includes('linkedin.com') || className.includes('linkedin') || dataAttrs.social === 'linkedin') {
            return 'linkedin';
        }
        if (href.includes('reddit.com') || className.includes('reddit') || dataAttrs.social === 'reddit') {
            return 'reddit';
        }
        
        return null;
    }

    identifySocialReferrer(referrer) {
        const socialPlatforms = {
            'facebook.com': 'facebook',
            'twitter.com': 'twitter',
            't.co': 'twitter',
            'linkedin.com': 'linkedin',
            'reddit.com': 'reddit',
            'instagram.com': 'instagram',
            'youtube.com': 'youtube',
            'pinterest.com': 'pinterest'
        };
        
        for (const [domain, platform] of Object.entries(socialPlatforms)) {
            if (referrer.includes(domain)) {
                return platform;
            }
        }
        
        return null;
    }

    bindEvents() {
        // Track page title changes (for SPAs)
        const titleObserver = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.type === 'childList' && mutation.target === document.head) {
                    const newTitle = document.title;
                    if (newTitle !== this.pageMetadata.title) {
                        this.pageMetadata.title = newTitle;
                        this.core.sendEvent('seo_event', {
                            type: 'title_change',
                            newTitle: newTitle,
                            url: window.location.href
                        });
                    }
                }
            });
        });
        
        titleObserver.observe(document.head, { childList: true, subtree: true });

        // Track URL changes (for SPAs)
        let currentUrl = window.location.href;
        setInterval(() => {
            if (window.location.href !== currentUrl) {
                currentUrl = window.location.href;
                this.analyzeCurrentPage();
            }
        }, 1000);
    }

    // SEO Score calculation
    calculateSEOScore() {
        let score = 0;
        const issues = [];
        const recommendations = [];

        // Title analysis
        if (this.pageMetadata.title) {
            if (this.pageMetadata.title.length >= 30 && this.pageMetadata.title.length <= 60) {
                score += 10;
            } else {
                issues.push('Title length should be between 30-60 characters');
                recommendations.push('Optimize title length for better search engine display');
            }
        } else {
            issues.push('Missing page title');
            recommendations.push('Add a descriptive page title');
        }

        // Meta description
        if (this.pageMetadata.description) {
            if (this.pageMetadata.description.length >= 120 && this.pageMetadata.description.length <= 160) {
                score += 10;
            } else {
                issues.push('Meta description length should be between 120-160 characters');
                recommendations.push('Optimize meta description length');
            }
        } else {
            issues.push('Missing meta description');
            recommendations.push('Add a compelling meta description');
        }

        // Heading structure
        const h1Count = this.pageMetadata.headings.filter(h => h.level === 1).length;
        if (h1Count === 1) {
            score += 10;
        } else if (h1Count === 0) {
            issues.push('Missing H1 tag');
            recommendations.push('Add exactly one H1 tag to the page');
        } else {
            issues.push('Multiple H1 tags found');
            recommendations.push('Use only one H1 tag per page');
        }

        // Images with alt text
        if (this.pageMetadata.images.total > 0) {
            const altTextRatio = this.pageMetadata.images.withAlt / this.pageMetadata.images.total;
            if (altTextRatio >= 0.9) {
                score += 10;
            } else {
                issues.push(`${this.pageMetadata.images.withoutAlt} images missing alt text`);
                recommendations.push('Add descriptive alt text to all images');
            }
        }

        // Mobile optimization
        if (this.pageMetadata.mobileOptimized.hasViewportMeta) {
            score += 10;
        } else {
            issues.push('Missing viewport meta tag');
            recommendations.push('Add viewport meta tag for mobile optimization');
        }

        // Canonical URL
        if (this.pageMetadata.canonical) {
            score += 5;
        } else {
            issues.push('Missing canonical URL');
            recommendations.push('Add canonical URL to prevent duplicate content issues');
        }

        // Open Graph data
        if (Object.keys(this.pageMetadata.openGraph).length >= 3) {
            score += 5;
        } else {
            issues.push('Incomplete Open Graph data');
            recommendations.push('Add Open Graph tags for better social media sharing');
        }

        // Internal links
        if (this.pageMetadata.internalLinks.length >= 3) {
            score += 5;
        } else {
            issues.push('Few internal links found');
            recommendations.push('Add more internal links to improve site navigation');
        }

        // Page speed (if available)
        if (this.pageMetadata.pagespeed && this.pageMetadata.pagespeed.loadTime < 3000) {
            score += 10;
        } else {
            issues.push('Page load time exceeds 3 seconds');
            recommendations.push('Optimize page loading speed');
        }

        // Schema markup
        if (this.pageMetadata.schemaMarkup.length > 0) {
            score += 10;
        } else {
            issues.push('No structured data found');
            recommendations.push('Add schema markup for better search engine understanding');
        }

        return {
            score: Math.min(score, 100),
            maxScore: 100,
            percentage: Math.min(score, 100),
            issues: issues,
            recommendations: recommendations,
            rating: this.getSEORating(score)
        };
    }

    getSEORating(score) {
        if (score >= 80) return 'excellent';
        if (score >= 60) return 'good';
        if (score >= 40) return 'fair';
        return 'poor';
    }

    // Dashboard creation
    createSEODashboard(containerId) {
        const container = document.getElementById(containerId);
        if (!container) return;

        const seoScore = this.calculateSEOScore();

        container.innerHTML = `
            <div class="seo-dashboard">
                <div class="dashboard-header">
                    <h2><i class="fas fa-search"></i> SEO Analytics</h2>
                    <div class="dashboard-controls">
                        <button id="analyzePage" class="btn-test">
                            <i class="fas fa-search"></i> Analyze Page
                        </button>
                        <button id="refreshSEO" class="btn-refresh">
                            <i class="fas fa-sync-alt"></i> Refresh
                        </button>
                    </div>
                </div>

                <div class="seo-score-section">
                    <h3><i class="fas fa-chart-pie"></i> SEO Score</h3>
                    <div class="score-display">
                        <div class="score-circle ${seoScore.rating}">
                            <span class="score-number">${seoScore.score}</span>
                            <span class="score-total">/100</span>
                        </div>
                        <div class="score-details">
                            <div class="score-rating ${seoScore.rating}">${seoScore.rating.toUpperCase()}</div>
                            <div class="score-description">SEO Optimization Score</div>
                        </div>
                    </div>
                </div>

                <div class="seo-metrics">
                    <div class="metrics-section">
                        <h3><i class="fas fa-tags"></i> Meta Information</h3>
                        <div class="meta-analysis">
                            <div class="meta-item">
                                <span class="meta-label">Title:</span>
                                <span class="meta-value">${this.pageMetadata.title || 'Missing'}</span>
                                <span class="meta-length">(${(this.pageMetadata.title || '').length} chars)</span>
                            </div>
                            <div class="meta-item">
                                <span class="meta-label">Description:</span>
                                <span class="meta-value">${this.pageMetadata.description || 'Missing'}</span>
                                <span class="meta-length">(${(this.pageMetadata.description || '').length} chars)</span>
                            </div>
                            <div class="meta-item">
                                <span class="meta-label">Keywords:</span>
                                <span class="meta-value">${this.pageMetadata.keywords || 'Not specified'}</span>
                            </div>
                        </div>
                    </div>

                    <div class="metrics-section">
                        <h3><i class="fas fa-heading"></i> Content Structure</h3>
                        <div id="heading-structure" class="structure-analysis">
                            ${this.renderHeadingStructure()}
                        </div>
                    </div>
                </div>

                <div class="seo-issues">
                    <h3><i class="fas fa-exclamation-triangle"></i> Issues & Recommendations</h3>
                    <div class="issues-list">
                        ${seoScore.issues.map(issue => `
                            <div class="issue-item">
                                <i class="fas fa-exclamation-circle"></i>
                                <span>${issue}</span>
                            </div>
                        `).join('')}
                    </div>
                    <div class="recommendations-list">
                        ${seoScore.recommendations.map(rec => `
                            <div class="recommendation-item">
                                <i class="fas fa-lightbulb"></i>
                                <span>${rec}</span>
                            </div>
                        `).join('')}
                    </div>
                </div>

                <div class="search-traffic">
                    <h3><i class="fas fa-chart-line"></i> Search Traffic</h3>
                    <div id="search-traffic-data">
                        ${this.searchData.searchEngine ? `
                            <div class="traffic-item">
                                <strong>Search Engine:</strong> ${this.searchData.searchEngine}
                            </div>
                            <div class="traffic-item">
                                <strong>Keywords:</strong> ${this.searchData.keywords || 'Not available'}
                            </div>
                        ` : '<div class="no-data">No search traffic detected for this session</div>'}
                    </div>
                </div>
            </div>
        `;

        this.bindSEODashboardEvents();
    }

    renderHeadingStructure() {
        return this.pageMetadata.headings.map(heading => `
            <div class="heading-item level-${heading.level}">
                <span class="heading-level">H${heading.level}</span>
                <span class="heading-text">${heading.text}</span>
            </div>
        `).join('');
    }

    bindSEODashboardEvents() {
        const analyzeBtn = document.getElementById('analyzePage');
        if (analyzeBtn) {
            analyzeBtn.addEventListener('click', () => {
                this.analyzeCurrentPage();
                this.createSEODashboard(analyzeBtn.closest('.seo-dashboard').parentElement.id);
            });
        }

        const refreshBtn = document.getElementById('refreshSEO');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => {
                this.createSEODashboard(refreshBtn.closest('.seo-dashboard').parentElement.id);
            });
        }
    }

    // Public API methods
    getPageMetadata() {
        return this.pageMetadata;
    }

    getSearchData() {
        return this.searchData;
    }

    getSEOScore() {
        return this.calculateSEOScore();
    }
}

// Register module
if (typeof window !== 'undefined') {
    window.SeoAnalyticsModule = SeoAnalyticsModule;
}