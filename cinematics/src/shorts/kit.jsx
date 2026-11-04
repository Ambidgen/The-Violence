// The short-form kit: the furniture a five-to-ten second in-game cutscene needs.
//
// The four opening scenes (C1-C4) are films. These are interstitials: a single idea,
// one movement, out again before the player wants the mouse back. Everything here is
// built from the same page as the openings — paper, ink, stepped greys and one red,
// which still only ever marks where a plan touched a real room (a breach, a route, a
// consequence). Nothing decorative is red.
//
// Every short is prop-driven and publishes its text slots, so the game can hand one
// video to many events: the plate is drawn here, the name on it is drawn by the engine.
import React from 'react';
import {AbsoluteFill, useCurrentFrame, useVideoConfig, interpolate, spring, Easing} from 'remotion';
import {C, FONT, clamp, ease, prog, rnd, Paper, Stamp, Sfx, Bed, Draw, PlanFigure, Halftone} from '../ink.jsx';
import {Fades} from '../ink.jsx';

export const W = 1920;
export const H = 1080;

// ------------------------------------------------------------------ page furniture
/** Four corner registration marks: the sheet is on a light table. */
export const Marks = ({inset = 30, len = 24, opacity = 0.38}) => {
  const s = {stroke: C.ink, strokeWidth: 2, opacity};
  return (
    <svg width={W} height={H} style={{position: 'absolute'}}>
      {[[inset, inset, 1, 1], [W - inset, inset, -1, 1], [inset, H - inset, 1, -1], [W - inset, H - inset, -1, -1]].map(([x, y, sx, sy], i) => (
        <g key={i}>
          <line x1={x} y1={y} x2={x + len * sx} y2={y} {...s} />
          <line x1={x} y1={y} x2={x} y2={y + len * sy} {...s} />
        </g>
      ))}
    </svg>
  );
};

/** The department slug, bottom left: the quiet bit of chrome every short carries. */
export const Slug = ({note = '', right = '', color = C.mid, show = true}) => (
  <div style={{position: 'absolute', left: 44, right: 44, bottom: 26, display: show ? 'flex' : 'none', justifyContent: 'space-between',
    fontFamily: FONT.caps, fontSize: 15, letterSpacing: 5, color, opacity: 0.85}}>
    <span>PORT CARRICK POLICE DEPARTMENT{note ? ` · ${note}` : ''}</span>
    <span>{right}</span>
  </div>
);

/** The frame every short sits in: paper, marks, slug, fades, optional ambience. */
export const Scene = ({len, note = '', right = '', bed = 'amb_office', bedVol = 0.32, children,
  fadeIn = 8, fadeOut = 12, grid = true, tone = C.paper, fadeTone = null, slugColor = null, showSlug = true,
  showSlots = false, slots = []}) => {
  const f = useCurrentFrame();
  const fo = interpolate(f, [0, fadeIn, len - fadeOut, len], [1, 0, 0, 1], clamp);
  return (
    <AbsoluteFill style={{background: tone}}>
      {bed ? <Bed name={bed} volume={bedVol} total={len} /> : null}
      <Paper grid={grid} tone={tone}>{children}</Paper>
      <Marks />
      <Slug note={note} right={right} color={slugColor || C.mid} show={showSlug} />
      {showSlots && slots.length ? (
        <svg width={W} height={H} style={{position: 'absolute'}}>
          {slots.map((s) => (
            <g key={s.id} opacity={0.8}>
              <rect x={s.x * W} y={s.y * H} width={s.w * W} height={s.h * H} fill="none" stroke={C.red} strokeWidth={2} strokeDasharray="8 6" />
              <text x={s.x * W + 8} y={s.y * H - 8} fontFamily={FONT.caps} fontSize={16} fill={C.red} letterSpacing={2}>{s.id}</text>
            </g>
          ))}
        </svg>
      ) : null}
      <AbsoluteFill style={{background: fadeTone || tone, opacity: fo, pointerEvents: 'none'}} />
    </AbsoluteFill>
  );
};

/** Reveal: opacity plus a short slide, from `at`. */
export const At = ({at = 0, dur = 10, from = 'up', dist = 26, children, style = {}, scaleFrom = 1, easeFn = ease}) => {
  const f = useCurrentFrame();
  if (f < at) return null;
  const p = prog(f, at, at + dur, easeFn);
  const d = {up: [0, dist], down: [0, -dist], left: [dist, 0], right: [-dist, 0], none: [0, 0]}[from];
  return (
    <div style={{position: 'absolute', ...style, opacity: p,
      transform: `translate(${d[0] * (1 - p)}px, ${d[1] * (1 - p)}px) scale(${1 + (scaleFrom - 1) * (1 - p)})`}}>
      {children}
    </div>
  );
};

/** A sheet of paper on the page: cut edge, ink border, offset shadow. */
export const Sheet = ({x, y, w, h, rot = 0, at = 0, from = 'down', fill = C.paper, border = 6, pad = 0, children, style = {}, shadow = 12}) => {
  const f = useCurrentFrame();
  if (f < at) return null;
  const p = prog(f, at, at + 12);
  const d = {up: [0, 40], down: [0, -40], left: [60, 0], right: [-60, 0], none: [0, 0]}[from];
  return (
    <div style={{position: 'absolute', left: x + d[0] * (1 - p), top: y + d[1] * (1 - p), width: w, height: h,
      transform: `rotate(${rot}deg)`, opacity: p, background: fill, border: `${border}px solid ${C.ink}`,
      boxSizing: 'border-box', padding: pad, boxShadow: `${shadow}px ${shadow}px 0 rgba(18,18,18,0.16)`, ...style}}>
      {children}
    </div>
  );
};

/** A kicker: small caps, tracked out, with a short rule under it. */
export const Kicker = ({children, at = 0, rule = true, color = C.mid, size = 20, style = {}}) => {
  const f = useCurrentFrame();
  return (
    <At at={at} from="none" style={style}>
      <div style={{fontFamily: FONT.caps, fontSize: size, letterSpacing: 8, color, textTransform: 'uppercase'}}>{children}</div>
      {rule ? <div style={{height: 2, background: C.ink, opacity: 0.6, marginTop: 8, width: '100%'}} /> : null}
    </At>
  );
};

/** A large capital heading. */
export const Head = ({children, size = 96, weight = 600, color = C.ink, style = {}, at = 0, from = 'up'}) => (
  <At at={at} from={from} style={style}>
    <div style={{fontFamily: FONT.caps, fontWeight: weight, fontSize: size, lineHeight: 0.98, letterSpacing: 2, color}}>{children}</div>
  </At>
);

/** Typewriter text on the page, with the blinking caret. */
export const Typer = ({text, at = 0, cps = 40, size = 30, color = C.ink, style = {}, family = FONT.type, weight = 400,
  caret = true, lineHeight = 1.35, letterSpacing = 0.4, until = Infinity}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  if (f < at || f > until) return null;
  const n = Math.max(0, Math.floor(((f - at) / fps) * cps));
  const shown = text.slice(0, n);
  return (
    <div style={{position: 'absolute', fontFamily: family, fontWeight: weight, fontSize: size, lineHeight, color,
      letterSpacing, whiteSpace: 'pre-wrap', ...style}}>
      {shown}
      {caret ? <span style={{opacity: shown.length < text.length && Math.floor(f / 7) % 2 === 0 ? 1 : 0}}>▌</span> : null}
    </div>
  );
};

/** A horizontal meter in the game's hand: outline, ink fill, optional red threshold. */
export const Meter = ({x, y, w, h = 22, value = 0, of = 100, at = 0, dur = 24, fill = C.ink, red = false,
  threshold = null, ticks = 0, label = null}) => {
  const f = useCurrentFrame();
  const p = prog(f, at, at + dur, Easing.out(Easing.cubic));
  const v = Math.max(0, Math.min(of, value));
  const cut = f >= at;
  return (
    <g opacity={cut ? 1 : 0}>
      <rect x={x} y={y} width={w} height={h} fill={C.paper} stroke={C.ink} strokeWidth={2.5} />
      <rect x={x} y={y} width={(w * v * p) / of} height={h} fill={red ? C.red : fill} />
      {Array.from({length: ticks}, (_, i) => (
        <line key={i} x1={x + (w * (i + 1)) / (ticks + 1)} y1={y} x2={x + (w * (i + 1)) / (ticks + 1)} y2={y + h} stroke={C.ink} strokeWidth={1} opacity={0.35} />
      ))}
      {threshold !== null ? (
        <line x1={x + (w * threshold) / of} y1={y - 7} x2={x + (w * threshold) / of} y2={y + h + 7} stroke={C.red} strokeWidth={4} />
      ) : null}
      {label ? <text x={x + w + 16} y={y + h - 4} fontFamily={FONT.caps} fontSize={h + 4} fill={C.ink}>{label}</text> : null}
    </g>
  );
};

/** An evidence marker: a numbered card laid on the plan. */
export const Marker = ({x, y, n, at = 0, size = 30}) => {
  const f = useCurrentFrame();
  if (f < at) return null;
  const p = spring({frame: f - at, fps: 30, config: {damping: 14, mass: 0.5}});
  return (
    <g opacity={Math.min(1, p)} transform={`translate(${x},${y}) scale(${0.8 + 0.2 * p})`}>
      <rect x={-size / 2} y={-size / 2} width={size} height={size} fill={C.paper} stroke={C.ink} strokeWidth={2.6} />
      <text x={0} y={size * 0.27} textAnchor="middle" fontFamily={FONT.caps} fontWeight={600} fontSize={size * 0.62} fill={C.ink}>{n}</text>
      <rect x={-size / 2 - 4} y={-size / 2 - 4} width={size + 8} height={size + 8} fill="none" stroke={C.ink} strokeWidth={1.2} opacity={0.4} />
    </g>
  );
};

/** A red cross, drawn on: the one mark that means the plan reached the room. */
export const RedCross = ({x, y, r = 34, at = 0, dur = 10, width = 7}) => {
  const f = useCurrentFrame();
  const p = prog(f, at, at + dur);
  if (p <= 0) return null;
  return (
    <g stroke={C.red} strokeWidth={width} strokeLinecap="round" opacity={0.9}>
      <line x1={x - r} y1={y - r} x2={x - r + 2 * r * p} y2={y - r + 2 * r * p} />
      <line x1={x + r} y1={y - r} x2={x + r - 2 * r * p} y2={y - r + 2 * r * p} />
    </g>
  );
};

/** A rubber stamp that slams: thin wrapper over Stamp with a sound at the same frame. */
export const Slam = ({lines, at, x, y, rot = -4, color = C.ink, size = 34, w = null, sound = true, vol = 0.6}) => (
  <>
    <Stamp lines={lines} at={at} x={x} y={y} rot={rot} color={color} size={size} w={w} />
    {sound ? <Sfx name="stamp" at={at} volume={vol} /> : null}
  </>
);

/** A short red rule, drawn on. Used for consequence only. */
export const RedRule = ({x, y, w = 300, at = 0, dur = 14, h = 6, opacity = 1}) => {
  const f = useCurrentFrame();
  const p = prog(f, at, at + dur);
  if (p <= 0) return null;
  return <rect x={x} y={y} width={w * p} height={h} fill={C.red} opacity={opacity} />;
};

/** An ink rule, drawn on. */
export const Rule = ({x, y, w = 300, at = 0, dur = 14, h = 3, color = C.ink, opacity = 1}) => {
  const f = useCurrentFrame();
  const p = prog(f, at, at + dur);
  if (p <= 0) return null;
  return <rect x={x} y={y} width={w * p} height={h} fill={color} opacity={opacity} />;
};

/** A plan figure that walks a polyline between two frames. */
export const Walker = ({pts, a, b, k = 0, scale = 1, gun = true, mark = 'bar', hover = false, at = 0, opacity = 1}) => {
  const f = useCurrentFrame();
  if (f < at) return null;
  const t = interpolate(f, [a, b], [0, 1], clamp);
  const [x, y, rot] = along(pts, t);
  const bob = hover ? 0 : Math.sin(f * 0.9 + k) * 0;
  return <PlanFigure x={x} y={y + bob} rot={rot} scale={scale} gun={gun} mark={mark} opacity={opacity} />;
};

/** Point and heading a fraction of the way along a polyline. */
export const along = (pts, t) => {
  const seg = [];
  let total = 0;
  for (let i = 1; i < pts.length; i++) {
    const l = Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]);
    seg.push(l);
    total += l;
  }
  let d = Math.max(0, Math.min(1, t)) * total;
  for (let i = 0; i < seg.length; i++) {
    if (d <= seg[i] || i === seg.length - 1) {
      const k = seg[i] === 0 ? 0 : Math.min(1, d / seg[i]);
      const p0 = pts[i], p1 = pts[i + 1];
      return [p0[0] + (p1[0] - p0[0]) * k, p0[1] + (p1[1] - p0[1]) * k, (Math.atan2(p1[1] - p0[1], p1[0] - p0[0]) * 180) / Math.PI];
    }
    d -= seg[i];
  }
  const p0 = pts[pts.length - 2], p1 = pts[pts.length - 1];
  return [p1[0], p1[1], (Math.atan2(p1[1] - p0[1], p1[0] - p0[0]) * 180) / Math.PI];
};

/** The polyline as SVG path data. */
export const pathOf = (pts) => pts.map(([x, y], i) => `${i ? 'L' : 'M'}${x},${y}`).join(' ');

/** A wall from (x1,y1) to (x2,y2), drawn on like a pen stroke. */
export const Wall = ({x1, y1, x2, y2, at = 0, dur = 16, w = 10}) => (
  <Draw d={`M${x1},${y1} L${x2},${y2}`} a={at} b={at + dur} width={w} len={Math.hypot(x2 - x1, y2 - y1) + 20} />
);

/** A numbered checkpoint ring on a route. */
export const Step = ({x, y, n, at = 0, color = C.ink, fill = C.paper, r = 21}) => {
  const f = useCurrentFrame();
  if (f < at) return null;
  const p = prog(f, at, at + 8);
  return (
    <g opacity={p} transform={`translate(${x},${y}) scale(${0.9 + 0.1 * p})`}>
      <circle r={r} fill={fill} stroke={color} strokeWidth={3} />
      <text y={r * 0.35} textAnchor="middle" fontFamily={FONT.caps} fontSize={r * 0.95} fill={C.ink}>{n}</text>
    </g>
  );
};

/** Halftone wash over a region, for fog, smoke and the parts nobody has looked at. */
export const Wash = ({id, x, y, w, h, opacity = 0.3, step = 11, r = 2.2, angle = 30}) => (
  <g>
    <defs>
      <pattern id={id} width={step} height={step} patternUnits="userSpaceOnUse" patternTransform={`rotate(${angle})`}>
        <circle cx={step / 2} cy={step / 2} r={r} fill={C.ink} />
      </pattern>
    </defs>
    <rect x={x} y={y} width={w} height={h} fill={`url(#${id})`} opacity={opacity} />
  </g>
);

/** A small paper label with a leader line, as drawn on the plan in the briefings. */
export const Label = ({x, y, tx, ty, text, at = 0, color = C.ink, size = 20, bg = C.paper}) => {
  const f = useCurrentFrame();
  const p = prog(f, at, at + 10);
  if (p <= 0) return null;
  const w = text.length * size * 0.62 + 18;
  return (
    <g opacity={p}>
      <line x1={x} y1={y} x2={tx} y2={ty} stroke={color} strokeWidth={1.6} />
      <circle cx={x} cy={y} r={4} fill={color} />
      <rect x={tx - 6} y={ty - size - 6} width={w} height={size + 14} fill={bg} stroke={color} strokeWidth={2.2} />
      <text x={tx + 3} y={ty} fontFamily={FONT.caps} fontSize={size} letterSpacing={2} fill={color}>{text}</text>
    </g>
  );
};

/** A redaction bar: the parts of a file the department will not show you. */
export const Redact = ({x, y, w, h = 24, at = 0, color = C.ink, opacity = 0.92}) => {
  const f = useCurrentFrame();
  const p = prog(f, at, at + 8);
  if (p <= 0) return null;
  return <rect x={x} y={y} width={w * p} height={h} fill={color} opacity={opacity} />;
};

/** Re-export the pieces the scenes share from the opening's kit. */
export {C, FONT, prog, rnd, clamp, ease, PlanFigure, Draw, Stamp, Sfx, Halftone};
