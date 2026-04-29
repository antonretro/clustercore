/**
 * CLUSTERCORE - MUSIC MANAGER (Howler.js)
 */
class MusicManager {
    constructor() {
        this.enabled = true;
        this.currentTrack = null;
        this.introSound = null;
        this.loopSound = null;
        this.singleSound = null;
        this.transitionToken = 0;
        this.volume = 0.3;
        this.howlerReady = (typeof Howl === 'function' && typeof Howler !== 'undefined');

        this.tracks = {
            menu: {
                intro: 'audio/music/game-intro.ogg',
                loop: 'audio/music/game-loop.ogg',
                outro: 'audio/music/game-outro.ogg'
            },
            game: {
                intro: 'audio/music/game-intro.ogg',
                loop: 'audio/music/game-loop.ogg',
                outro: 'audio/music/game-outro.ogg'
            },
            gameover: {
                single: 'audio/music/game-outro.ogg'
            }
        };

        if (!this.howlerReady) {
            console.warn('ClusterCore MusicManager: Howler is unavailable. Music disabled.');
            this.enabled = false;
            return;
        }

        this.syncVolumeFromUI();
    }

    clampVolume(value) {
        return Math.max(0, Math.min(1, value));
    }

    readSliderValue(primaryId, fallbackId, defaultValue) {
        const primary = document.getElementById(primaryId);
        const fallback = fallbackId ? document.getElementById(fallbackId) : null;
        const raw = primary ? primary.value : (fallback ? fallback.value : defaultValue);
        const parsed = Number(raw);
        return Number.isFinite(parsed) ? parsed : defaultValue;
    }

    getComputedVolume() {
        const master = this.readSliderValue('settings-vol-master', 'vol-master', 50) / 100;
        const music = this.readSliderValue('settings-vol-music', 'vol-music', 30) / 100;
        return this.clampVolume(master * music);
    }

    createHowl(src, loop = false) {
        return new Howl({
            src: [src],
            loop,
            volume: this.volume,
            preload: true,
            html5: false,
            onloaderror: (_id, err) => {
                console.warn(`ClusterCore music load failed (${src}):`, err);
            },
            onplayerror: (_id, err) => {
                console.warn(`ClusterCore music play failed (${src}):`, err);
            }
        });
    }

    unload(sound) {
        if (!sound) return;
        try {
            sound.stop();
            sound.unload();
        } catch (e) {
            console.warn('ClusterCore music unload warning:', e);
        }
    }

    syncVolumeFromUI() {
        this.setVolume(this.getComputedVolume());
    }

    play(trackName) {
        if (!this.enabled || !this.howlerReady) return;

        const track = this.tracks[trackName];
        if (!track) return;

        this.transitionToken++;
        const token = this.transitionToken;

        this.stop(false);
        this.currentTrack = trackName;
        this.syncVolumeFromUI();

        if (track.single) {
            this.singleSound = this.createHowl(track.single, false);
            this.singleSound.play();
            return;
        }

        if (track.intro) {
            this.introSound = this.createHowl(track.intro, false);
            this.introSound.once('end', () => {
                if (token !== this.transitionToken || !this.enabled) return;
                if (!track.loop) return;

                this.loopSound = this.createHowl(track.loop, true);
                this.loopSound.play();
            });
            this.introSound.play();
            return;
        }

        if (track.loop) {
            this.loopSound = this.createHowl(track.loop, true);
            this.loopSound.play();
        }
    }

    playLoop(loopPath) {
        if (!this.enabled || !this.howlerReady || !loopPath) return;
        this.transitionToken++;
        this.stop(false);
        this.syncVolumeFromUI();
        this.loopSound = this.createHowl(loopPath, true);
        this.loopSound.play();
    }

    stop(playOutro = false) {
        if (!this.howlerReady) return;

        const previousTrack = this.currentTrack;
        this.transitionToken++;

        this.unload(this.introSound);
        this.unload(this.loopSound);
        this.unload(this.singleSound);
        this.introSound = null;
        this.loopSound = null;
        this.singleSound = null;
        this.currentTrack = null;

        if (!playOutro || !previousTrack || !this.enabled) return;
        const outroPath = this.tracks[previousTrack] && this.tracks[previousTrack].outro;
        if (!outroPath) return;

        const outro = this.createHowl(outroPath, false);
        outro.once('end', () => {
            outro.unload();
        });
        outro.play();
    }

    fadeOut(sound, duration, callback) {
        if (!sound || !this.howlerReady) {
            if (callback) callback();
            return;
        }

        const from = typeof sound.volume === 'function' ? sound.volume() : this.volume;
        sound.fade(from, 0, duration);
        setTimeout(() => {
            this.unload(sound);
            if (callback) callback();
        }, duration + 20);
    }

    setVolume(vol) {
        this.volume = this.clampVolume(vol);

        if (this.introSound) this.introSound.volume(this.volume);
        if (this.loopSound) this.loopSound.volume(this.volume);
        if (this.singleSound) this.singleSound.volume(this.volume);
    }

    setEnabled(enabled) {
        this.enabled = !!enabled;
        if (!this.howlerReady) return;

        Howler.mute(!this.enabled);
        if (!this.enabled) {
            this.stop(false);
        } else {
            this.syncVolumeFromUI();
        }
    }
}

const musicManager = new MusicManager();
