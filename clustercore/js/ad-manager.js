class AdManager {
    constructor() {
        this.isNative = window.Capacitor && window.Capacitor.isNative;
        this.adsEnabled = true;
        this.checkIAP();
    }

    async checkIAP() {
        // Check if user has purchased "Remove Ads"
        // In a real app, you'd check local storage or restore purchases via Capacitor IAP
        const purchased = localStorage.getItem('remove_ads') === 'true';
        if (purchased) {
            this.adsEnabled = false;
            console.log('AdManager: Ads removed via purchase.');
        }
    }

    async showBanner() {
        if (!this.adsEnabled) return;

        if (this.isNative) {
            console.log('AdManager: Showing Native Banner');
            // Placeholder for Capacitor AdMob call
            // await AdMob.showBanner(options);
        } else {
            console.log('AdManager: Web Mode - Banner would show here');
            // Optional: Show a fake banner div for testing
        }
    }

    async hideBanner() {
        if (this.isNative) {
            // await AdMob.hideBanner();
        }
    }

    async showInterstitial() {
        if (!this.adsEnabled) return;

        if (this.isNative) {
            console.log('AdManager: Showing Native Interstitial');
            // await AdMob.prepareInterstitial(options);
            // await AdMob.showInterstitial();
        } else {
            console.log('AdManager: Web Mode - Interstitial would show here');
            alert('[AdManager Mock] Interstitial Ad Displayed');
        }
    }

    async purchaseRemoveAds() {
        if (this.isNative) {
            console.log('AdManager: Initiating Native Purchase');
            // await InAppPurchase.purchase({ productId: 'remove_ads' });
        } else {
            // Web Mock
            const confirm = window.confirm('Mock Purchase: Remove Ads for $0.99?');
            if (confirm) {
                this.adsEnabled = false;
                localStorage.setItem('remove_ads', 'true');
                alert('Ads Removed!');
                // Hide any active banners
                this.hideBanner();
                // Refresh UI if needed
                location.reload();
            }
        }
    }
}
