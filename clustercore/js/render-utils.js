(function attachClusterCoreRenderUtils(global) {
    function drawPieceGlyph(context, pieceId, size, fillStyle = 'rgba(0, 0, 0, 0.15)') {
        if (!Number.isInteger(pieceId) || pieceId < 1 || pieceId > 6) return;

        const sz = size * 0.35;
        context.fillStyle = fillStyle;
        context.beginPath();

        switch (pieceId) {
            case 1: // Circle
                context.arc(0, 0, sz, 0, Math.PI * 2);
                break;
            case 2: // Triangle
                context.moveTo(0, -sz);
                context.lineTo(sz, sz);
                context.lineTo(-sz, sz);
                context.closePath();
                break;
            case 3: { // Star
                const spikes = 5;
                const outerRadius = sz;
                const innerRadius = sz / 2;
                let rot = Math.PI / 2 * 3;
                let x = 0;
                let y = 0;
                const step = Math.PI / spikes;

                context.moveTo(0, -outerRadius);
                for (let i = 0; i < spikes; i++) {
                    x = Math.cos(rot) * outerRadius;
                    y = Math.sin(rot) * outerRadius;
                    context.lineTo(x, y);
                    rot += step;

                    x = Math.cos(rot) * innerRadius;
                    y = Math.sin(rot) * innerRadius;
                    context.lineTo(x, y);
                    rot += step;
                }
                context.lineTo(0, -outerRadius);
                context.closePath();
                break;
            }
            case 4: // Square
                context.rect(-sz, -sz, sz * 2, sz * 2);
                break;
            case 5: // Diamond
                context.moveTo(0, -sz);
                context.lineTo(sz, 0);
                context.lineTo(0, sz);
                context.lineTo(-sz, 0);
                context.closePath();
                break;
            case 6: // Hexagon
                context.moveTo(sz, 0);
                for (let i = 1; i < 6; i++) {
                    context.lineTo(sz * Math.cos(i * Math.PI / 3), sz * Math.sin(i * Math.PI / 3));
                }
                context.closePath();
                break;
        }

        context.fill();
    }

    global.ClusterCoreRenderUtils = {
        drawPieceGlyph
    };
})(window);
