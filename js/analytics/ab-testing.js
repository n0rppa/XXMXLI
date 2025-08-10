/**
 * XXMXLI A/B Testing Module
 * Split testing framework, traffic splitting, statistical significance
 */

class AbTestingModule {
    constructor(core) {
        this.core = core;
        this.config = {
            tests: {},
            defaultTrafficSplit: 50, // 50/50 split
            minimumSampleSize: 100,
            confidenceLevel: 0.95,
            enabled: true
        };
        
        this.activeTests = new Map();
        this.userVariants = new Map();
        this.testResults = new Map();
    }

    async init() {
        await this.loadActiveTests();
        this.assignUserToVariants();
        this.applyVariants();
        this.bindEvents();
        
        if (this.core.config.debug) {
            console.log('🧪 A/B Testing module initialized', this.activeTests);
        }
    }

    async loadActiveTests() {
        try {
            const response = await fetch(`${this.core.config.endpoint}ab-tests.php`);
            const data = await response.json();
            
            if (data.status === 'success') {
                this.config.tests = data.tests;
                
                // Set up active tests
                Object.entries(this.config.tests).forEach(([testId, test]) => {
                    if (test.status === 'active') {
                        this.activeTests.set(testId, test);
                    }
                });
            }
        } catch (error) {
            if (this.core.config.debug) {
                console.log('📝 No active A/B tests found, using defaults');
            }
            this.setupDefaultTests();
        }
    }

    setupDefaultTests() {
        // Default tests for demonstration
        const defaultTests = {
            'header_color': {
                name: 'Header Color Test',
                description: 'Test different header colors for better engagement',
                status: 'active',
                variants: {
                    'control': {
                        name: 'Original Green',
                        weight: 50,
                        changes: []
                    },
                    'variant_a': {
                        name: 'Cyan Accent',
                        weight: 50,
                        changes: [
                            {
                                type: 'css',
                                selector: '.header',
                                property: 'border-bottom-color',
                                value: '#00ffff'
                            },
                            {
                                type: 'css',
                                selector: '.nav-container a',
                                property: 'color',
                                value: '#00ffff'
                            }
                        ]
                    }
                },
                goal: 'contact_form',
                startDate: new Date().toISOString(),
                endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString() // 30 days
            },
            'cta_button': {
                name: 'Call-to-Action Button Test',
                description: 'Test different CTA button styles',
                status: 'active',
                variants: {
                    'control': {
                        name: 'Original Style',
                        weight: 50,
                        changes: []
                    },
                    'variant_b': {
                        name: 'Larger Button',
                        weight: 50,
                        changes: [
                            {
                                type: 'css',
                                selector: '.btn, button',
                                property: 'padding',
                                value: '15px 25px'
                            },
                            {
                                type: 'css',
                                selector: '.btn, button',
                                property: 'font-size',
                                value: '18px'
                            }
                        ]
                    }
                },
                goal: 'newsletter_signup',
                startDate: new Date().toISOString(),
                endDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString() // 14 days
            }
        };

        this.config.tests = defaultTests;
        
        Object.entries(defaultTests).forEach(([testId, test]) => {
            this.activeTests.set(testId, test);
        });
    }

    assignUserToVariants() {
        const userId = this.core.userId;
        
        this.activeTests.forEach((test, testId) => {
            // Check if user already has a variant assigned
            const existingVariant = localStorage.getItem(`ab_test_${testId}`);
            
            if (existingVariant && test.variants[existingVariant]) {
                this.userVariants.set(testId, existingVariant);
            } else {
                // Assign new variant based on weights
                const variant = this.selectVariantByWeight(test.variants);
                this.userVariants.set(testId, variant);
                localStorage.setItem(`ab_test_${testId}`, variant);
            }

            // Track variant assignment
            this.core.sendEvent('ab_test', {
                testId: testId,
                testName: test.name,
                variant: this.userVariants.get(testId),
                event: 'assignment'
            });
        });
    }

    selectVariantByWeight(variants) {
        const totalWeight = Object.values(variants).reduce((sum, v) => sum + v.weight, 0);
        let random = Math.random() * totalWeight;
        
        for (const [variantId, variant] of Object.entries(variants)) {
            random -= variant.weight;
            if (random <= 0) {
                return variantId;
            }
        }
        
        // Fallback to first variant
        return Object.keys(variants)[0];
    }

    applyVariants() {
        this.userVariants.forEach((variantId, testId) => {
            const test = this.activeTests.get(testId);
            const variant = test.variants[variantId];
            
            if (variant && variant.changes) {
                this.applyVariantChanges(variant.changes, testId, variantId);
            }
        });
    }

    applyVariantChanges(changes, testId, variantId) {
        changes.forEach(change => {
            switch (change.type) {
                case 'css':
                    this.applyCSSChange(change);
                    break;
                case 'html':
                    this.applyHTMLChange(change);
                    break;
                case 'attribute':
                    this.applyAttributeChange(change);
                    break;
                case 'class':
                    this.applyClassChange(change);
                    break;
                default:
                    console.warn(`Unknown change type: ${change.type}`);
            }
        });

        if (this.core.config.debug) {
            console.log(`🧪 Applied variant ${variantId} for test ${testId}`);
        }
    }

    applyCSSChange(change) {
        const elements = document.querySelectorAll(change.selector);
        elements.forEach(element => {
            element.style[change.property] = change.value;
            element.setAttribute('data-ab-test', 'true');
        });
    }

    applyHTMLChange(change) {
        const elements = document.querySelectorAll(change.selector);
        elements.forEach(element => {
            if (change.action === 'replace') {
                element.innerHTML = change.value;
            } else if (change.action === 'append') {
                element.innerHTML += change.value;
            } else if (change.action === 'prepend') {
                element.innerHTML = change.value + element.innerHTML;
            }
            element.setAttribute('data-ab-test', 'true');
        });
    }

    applyAttributeChange(change) {
        const elements = document.querySelectorAll(change.selector);
        elements.forEach(element => {
            element.setAttribute(change.attribute, change.value);
            element.setAttribute('data-ab-test', 'true');
        });
    }

    applyClassChange(change) {
        const elements = document.querySelectorAll(change.selector);
        elements.forEach(element => {
            if (change.action === 'add') {
                element.classList.add(change.className);
            } else if (change.action === 'remove') {
                element.classList.remove(change.className);
            } else if (change.action === 'toggle') {
                element.classList.toggle(change.className);
            }
            element.setAttribute('data-ab-test', 'true');
        });
    }

    bindEvents() {
        // Track conversions for A/B tests
        this.core.on('conversion', (data) => {
            this.trackTestConversion(data);
        });

        // Track other interactions
        document.addEventListener('click', (e) => {
            if (e.target.hasAttribute('data-ab-test')) {
                this.trackTestInteraction('click', e.target);
            }
        });
    }

    trackTestConversion(conversionData) {
        this.activeTests.forEach((test, testId) => {
            if (test.goal === conversionData.goalId) {
                const variant = this.userVariants.get(testId);
                
                this.core.sendEvent('ab_test', {
                    testId: testId,
                    testName: test.name,
                    variant: variant,
                    event: 'conversion',
                    goal: conversionData.goalId,
                    value: conversionData.value
                });

                if (this.core.config.debug) {
                    console.log(`🎯 A/B Test conversion: ${testId} - ${variant}`);
                }
            }
        });
    }

    trackTestInteraction(eventType, element) {
        // Find which test this element belongs to
        this.userVariants.forEach((variant, testId) => {
            this.core.sendEvent('ab_test', {
                testId: testId,
                variant: variant,
                event: 'interaction',
                interactionType: eventType,
                element: element.tagName.toLowerCase(),
                elementClass: element.className
            });
        });
    }

    // Statistical analysis methods
    async calculateStatisticalSignificance(testId) {
        try {
            const response = await fetch(`${this.core.config.endpoint}ab-test-results.php?test=${testId}`);
            const data = await response.json();
            
            if (data.status === 'success') {
                return this.performSignificanceTest(data.results);
            }
        } catch (error) {
            console.error('❌ Failed to calculate statistical significance:', error);
        }
        
        return null;
    }

    performSignificanceTest(results) {
        // Simplified statistical significance test
        // In production, you'd use a proper statistical library
        
        const variants = Object.keys(results);
        if (variants.length !== 2) {
            return { error: 'Statistical test requires exactly 2 variants' };
        }

        const [controlId, variantId] = variants;
        const control = results[controlId];
        const variant = results[variantId];

        // Calculate conversion rates
        const controlRate = control.conversions / control.visitors;
        const variantRate = variant.conversions / variant.visitors;

        // Calculate pooled standard error
        const pooledRate = (control.conversions + variant.conversions) / (control.visitors + variant.visitors);
        const standardError = Math.sqrt(pooledRate * (1 - pooledRate) * (1/control.visitors + 1/variant.visitors));

        // Calculate z-score
        const zScore = (variantRate - controlRate) / standardError;
        
        // Calculate p-value (simplified)
        const pValue = 2 * (1 - this.normalCDF(Math.abs(zScore)));
        
        // Determine significance
        const isSignificant = pValue < (1 - this.config.confidenceLevel);
        const improvement = ((variantRate - controlRate) / controlRate) * 100;

        return {
            controlRate: controlRate,
            variantRate: variantRate,
            improvement: improvement,
            zScore: zScore,
            pValue: pValue,
            isSignificant: isSignificant,
            confidenceLevel: this.config.confidenceLevel,
            sampleSize: {
                control: control.visitors,
                variant: variant.visitors
            }
        };
    }

    // Simplified normal CDF approximation
    normalCDF(x) {
        return 0.5 * (1 + this.erf(x / Math.sqrt(2)));
    }

    // Error function approximation
    erf(x) {
        const a1 =  0.254829592;
        const a2 = -0.284496736;
        const a3 =  1.421413741;
        const a4 = -1.453152027;
        const a5 =  1.061405429;
        const p  =  0.3275911;

        const sign = x >= 0 ? 1 : -1;
        x = Math.abs(x);

        const t = 1.0 / (1.0 + p * x);
        const y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * Math.exp(-x * x);

        return sign * y;
    }

    // Test management methods
    createTest(testConfig) {
        const testId = `test_${Date.now()}`;
        
        const test = {
            name: testConfig.name,
            description: testConfig.description || '',
            status: 'draft',
            variants: testConfig.variants,
            goal: testConfig.goal,
            startDate: testConfig.startDate || new Date().toISOString(),
            endDate: testConfig.endDate,
            createdBy: this.core.userId
        };

        // Send to backend for storage
        this.saveTest(testId, test);
        
        return testId;
    }

    async saveTest(testId, test) {
        try {
            const response = await fetch(`${this.core.config.endpoint}ab-test-manager.php`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    action: 'save',
                    testId: testId,
                    test: test
                })
            });
            
            const data = await response.json();
            return data.status === 'success';
        } catch (error) {
            console.error('❌ Failed to save A/B test:', error);
            return false;
        }
    }

    startTest(testId) {
        const test = this.config.tests[testId];
        if (test) {
            test.status = 'active';
            test.startDate = new Date().toISOString();
            this.activeTests.set(testId, test);
            this.saveTest(testId, test);
            
            if (this.core.config.debug) {
                console.log(`🚀 A/B Test started: ${testId}`);
            }
        }
    }

    stopTest(testId) {
        const test = this.config.tests[testId];
        if (test) {
            test.status = 'completed';
            test.endDate = new Date().toISOString();
            this.activeTests.delete(testId);
            this.saveTest(testId, test);
            
            if (this.core.config.debug) {
                console.log(`🏁 A/B Test stopped: ${testId}`);
            }
        }
    }

    // Dashboard creation
    createABTestingDashboard(containerId) {
        const container = document.getElementById(containerId);
        if (!container) return;

        container.innerHTML = `
            <div class="ab-testing-dashboard">
                <div class="dashboard-header">
                    <h2><i class="fas fa-flask"></i> A/B Testing</h2>
                    <div class="dashboard-controls">
                        <button id="createNewTest" class="btn-create">
                            <i class="fas fa-plus"></i> New Test
                        </button>
                        <button id="refreshTests" class="btn-refresh">
                            <i class="fas fa-sync-alt"></i> Refresh
                        </button>
                    </div>
                </div>

                <div class="active-tests-section">
                    <h3><i class="fas fa-play"></i> Active Tests</h3>
                    <div id="active-tests-list" class="tests-grid">
                        <!-- Active tests will be populated here -->
                    </div>
                </div>

                <div class="test-results-section">
                    <h3><i class="fas fa-chart-bar"></i> Test Results</h3>
                    <div id="test-results-container">
                        <!-- Test results will be populated here -->
                    </div>
                </div>

                <div class="user-variants-section">
                    <h3><i class="fas fa-user"></i> Your Current Variants</h3>
                    <div id="user-variants-list" class="variants-list">
                        <!-- User variants will be populated here -->
                    </div>
                </div>
            </div>
        `;

        this.updateABTestingDashboard();
        this.bindDashboardEvents();
    }

    bindDashboardEvents() {
        const createBtn = document.getElementById('createNewTest');
        if (createBtn) {
            createBtn.addEventListener('click', () => {
                this.showTestCreationModal();
            });
        }

        const refreshBtn = document.getElementById('refreshTests');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => {
                this.updateABTestingDashboard();
            });
        }
    }

    updateABTestingDashboard() {
        this.updateActiveTestsList();
        this.updateTestResults();
        this.updateUserVariantsList();
    }

    updateActiveTestsList() {
        const container = document.getElementById('active-tests-list');
        if (!container) return;

        container.innerHTML = Array.from(this.activeTests.entries()).map(([testId, test]) => `
            <div class="test-card active">
                <div class="test-header">
                    <h4>${test.name}</h4>
                    <div class="test-status active">Active</div>
                </div>
                <div class="test-description">${test.description}</div>
                <div class="test-variants">
                    ${Object.entries(test.variants).map(([variantId, variant]) => `
                        <div class="variant-item ${this.userVariants.get(testId) === variantId ? 'selected' : ''}">
                            <span class="variant-name">${variant.name}</span>
                            <span class="variant-weight">${variant.weight}%</span>
                        </div>
                    `).join('')}
                </div>
                <div class="test-actions">
                    <button onclick="window.xxmxliAnalytics.modules['ab-testing'].viewTestResults('${testId}')" class="btn-view">
                        <i class="fas fa-chart-line"></i> Results
                    </button>
                    <button onclick="window.xxmxliAnalytics.modules['ab-testing'].stopTest('${testId}')" class="btn-stop">
                        <i class="fas fa-stop"></i> Stop
                    </button>
                </div>
            </div>
        `).join('');
    }

    updateTestResults() {
        // Implementation for showing test results
        const container = document.getElementById('test-results-container');
        if (!container) return;

        container.innerHTML = `
            <div class="demo-placeholder">
                Test results and statistical significance will be displayed here.
                <br>Click "Results" on any active test to view detailed analytics.
            </div>
        `;
    }

    updateUserVariantsList() {
        const container = document.getElementById('user-variants-list');
        if (!container) return;

        container.innerHTML = Array.from(this.userVariants.entries()).map(([testId, variantId]) => {
            const test = this.activeTests.get(testId);
            const variant = test?.variants[variantId];
            
            return `
                <div class="variant-assignment">
                    <div class="assignment-test">${test?.name || testId}</div>
                    <div class="assignment-variant">${variant?.name || variantId}</div>
                </div>
            `;
        }).join('');
    }

    viewTestResults(testId) {
        console.log(`Viewing results for test: ${testId}`);
        // Implementation for detailed test results view
    }

    showTestCreationModal() {
        console.log('Opening test creation modal');
        // Implementation for test creation UI
    }

    // Public API
    getUserVariant(testId) {
        return this.userVariants.get(testId);
    }

    isInTest(testId) {
        return this.activeTests.has(testId);
    }

    getActiveTests() {
        return Array.from(this.activeTests.keys());
    }
}

// Register module
if (typeof window !== 'undefined') {
    window.AbTestingModule = AbTestingModule;
}