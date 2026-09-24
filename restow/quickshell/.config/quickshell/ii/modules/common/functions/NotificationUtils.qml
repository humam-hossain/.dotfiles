pragma Singleton
import Quickshell

Singleton {
    id: root
    /**
     * @param { string } summary 
     * @returns { string }
     */
    function findSuitableMaterialSymbol(summary = "") {
        const defaultType = 'chat';
        if (summary.length === 0) return defaultType;

        const keywordsToTypes = {
            'reboot': 'restart_alt',
            'record': 'screen_record',
            'battery': 'power',
            'power': 'power',
            'screenshot': 'screenshot_monitor',
            'welcome': 'waving_hand',
            'time': 'scheduleb',
            'installed': 'download',
            'configuration reloaded': 'reset_wrench',
            'unable': 'question_mark',
            "couldn't": 'question_mark',
            'config': 'reset_wrench',
            'update': 'update',
            'ai response': 'neurology',
            'control': 'settings',
            'upsca': 'compare',
            'music': 'queue_music',
            'install': 'deployed_code_update',
            'input': 'keyboard_alt',
            'preedit': 'keyboard_alt',
            'startswith:file': 'folder_copy', // Declarative startsWith check
        };

        const lowerSummary = summary.toLowerCase();

        for (const [keyword, type] of Object.entries(keywordsToTypes)) {
            if (keyword.startsWith('startswith:')) {
                const startsWithKeyword = keyword.replace('startswith:', '');
                if (lowerSummary.startsWith(startsWithKeyword)) {
                    return type;
                }
            } else if (lowerSummary.includes(keyword)) {
                return type;
            }
        }

        return defaultType;
    }

    /**
     * @param { number | string | Date } timestamp 
     * @returns { string }
     */
    function getFriendlyNotifTimeString(timestamp) {
        if (!timestamp) return '';
        const messageTime = new Date(timestamp);
        const now = new Date();
        const diffMs = now.getTime() - messageTime.getTime();

        // Less than 1 minute
        if (diffMs < 60000)
            return 'Now';

        // Same day - show relative time
        if (messageTime.toDateString() === now.toDateString()) {
            const diffMinutes = Math.floor(diffMs / 60000);
            const diffHours = Math.floor(diffMs / 3600000);

            if (diffHours > 0) {
                return `${diffHours}h`;
            } else {
                return `${diffMinutes}m`;
            }
        }

        // Yesterday
        if (messageTime.toDateString() === new Date(now.getTime() - 86400000).toDateString())
            return 'Yesterday';

        // Older dates
        return Qt.formatDateTime(messageTime, "MMMM dd");
    }

    function processNotificationBody(body, appName) {
        let processedBody = body
        
        // Clean Chromium-based browsers notifications - remove first line
        if (appName) {
            const lowerApp = appName.toLowerCase()
            const chromiumBrowsers = [
                "brave", "chrome", "chromium", "vivaldi", "opera", "microsoft edge"
            ]

            if (chromiumBrowsers.some(name => lowerApp.includes(name))) {
                const lines = body.split('\n\n')

                if (lines.length > 1 && lines[0].startsWith('<a')) {
                    processedBody = lines.slice(1).join('\n\n')
                }
            }
        }

        processedBody = processedBody.replace(/<img/gi, '\n\n<img');
        
        return processedBody
    }

    /**
     * Extracts 4-8 digit verification code, hyphenated code, or service-prefixed code
     * anchored to security keywords.
     * @param { string } body
     * @param { string } summary
     * @returns { string }
     */
    function extractOtpCode(body = "", summary = "") {
        const fullText = (summary ? summary + " " : "") + (body || "");
        if (!fullText) return "";
        const cleaned = fullText.replace(/<[^>]*>/g, " ");

        const keywords = "code|otp|verify|verification|pin|auth|2fa|security|one-time(?:\\s+password)?|password|passcode";
        const codePattern = "(?:[A-Za-z]{1,2}-\\d{4,8}|\\d{3,4}-\\d{3,4}|\\b\\d{4,8}\\b)";

        // 1. Keyword before code (e.g. "verification code is 482910", "code: G-123456", "PIN is 9482")
        const reKeywordBefore = new RegExp("(?:\\b(?:" + keywords + ")\\b)[^\\w\\r\\n]{0,30}?(?:is\\s+|:\\s*|\\s+)?(?<![-/0-9])(" + codePattern + ")(?![-/0-9])", "i");
        const m1 = cleaned.match(reKeywordBefore);
        if (m1 && m1[1]) return m1[1].trim();

        // 2. Code before keyword (e.g. "123-456 is your code", "Use 582910 for 2FA auth")
        const reCodeBefore = new RegExp("(?<![-/0-9])(" + codePattern + ")[^\\w\\r\\n]{0,30}?(?:is\\s+|for\\s+|as\\s+|to\\s+)?(?:\\b(?:" + keywords + ")\\b)", "i");
        const m2 = cleaned.match(reCodeBefore);
        if (m2 && m2[1]) return m2[1].trim();

        // 3. Proximity within sentence (e.g. "Your Google code is 839201. Sent on...")
        const reProximity = new RegExp("(?:\\b(?:" + keywords + ")\\b)[^\\r\\n]{1,60}?(?<![-/0-9])(" + codePattern + ")(?![-/0-9])", "i");
        const m3 = cleaned.match(reProximity);
        if (m3 && m3[1]) return m3[1].trim();

        const reProximityReverse = new RegExp("(?<![-/0-9])(" + codePattern + ")[^\\r\\n]{1,60}?(?:\\b(?:" + keywords + ")\\b)", "i");
        const m4 = cleaned.match(reProximityReverse);
        if (m4 && m4[1]) return m4[1].trim();

        return "";
    }

    /**
     * Extracts destination URL from Chromium HTML anchor (<a href="...">) or raw http(s) URL.
     * @param { string } body
     * @returns { string }
     */
    function extractUrl(body = "") {
        if (!body) return "";

        let url = "";

        // 1. HTML anchor tag href (Chromium notifications)
        const aMatch = body.match(/<a\s+[^>]*href=["']([^"']+)["']/i);
        if (aMatch && aMatch[1]) {
            url = aMatch[1].replace(/&amp;/g, "&").trim();
        } else {
            // 2. Standalone raw URL (strip trailing punctuation)
            const urlMatch = body.match(/\bhttps?:\/\/[^\s<>"'()]+[^\s<>"'().,;:!?]/i);
            if (urlMatch && urlMatch[0]) {
                url = urlMatch[0].replace(/&amp;/g, "&").trim();
            }
        }

        if (!url) return "";

        // Scheme whitelist: http:// or https:// only (T-40-03)
        if (!/^https?:\/\//i.test(url)) {
            return "";
        }

        return url;
    }
}

