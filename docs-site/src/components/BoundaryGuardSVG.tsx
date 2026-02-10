import React from "react";

export function BoundaryGuardSVG({ className = "", accentColor }) {
  return (
    <svg
      viewBox="0 0 200 200"
      width="100%"
      height="auto"
      preserveAspectRatio="xMidYMid meet"
      className={className}
      role="img"
      aria-labelledby="boundary-guard-title"
    >
      <title id="boundary-guard-title">
        Schema acting as boundary between external data and application core
      </title>

      {/* Left side: External world */}
      <g opacity="0.7">
        <rect
          x="15"
          y="50"
          width="60"
          height="30"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          rx="4"
        />
        <text
          x="45"
          y="70"
          fontSize="10"
          textAnchor="middle"
          fill="currentColor"
        >
          API
        </text>

        <rect
          x="15"
          y="120"
          width="60"
          height="30"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          rx="4"
        />
        <text
          x="45"
          y="140"
          fontSize="10"
          textAnchor="middle"
          fill="currentColor"
        >
          DB
        </text>
      </g>

      {/* Central barrier: The Guard */}
      <rect
        x="95"
        y="30"
        width="10"
        height="140"
        fill={accentColor || "var(--ifm-color-primary)"}
        opacity="0.15"
      />
      <rect
        x="95"
        y="30"
        width="10"
        height="140"
        fill="none"
        stroke={accentColor || "var(--ifm-color-primary)"}
        strokeWidth="3"
      />

      <text
        x="100"
        y="20"
        fontSize="11"
        fontWeight="600"
        textAnchor="middle"
        fill={accentColor || "var(--ifm-color-primary)"}
      >
        GUARD
      </text>

      {/* Shield icon on barrier */}
      <path
        d="M 100 90 L 95 95 L 95 105 Q 100 108 100 108 Q 105 108 105 105 L 105 95 Z"
        fill="none"
        stroke={accentColor || "var(--ifm-color-primary)"}
        strokeWidth="2"
      />

      {/* Right side: Safe core */}
      <g>
        <rect
          x="125"
          y="75"
          width="60"
          height="50"
          fill={accentColor || "var(--ifm-color-primary)"}
          fillOpacity="0.08"
          stroke="currentColor"
          strokeWidth="2"
          rx="4"
        />
        <text
          x="155"
          y="95"
          fontSize="10"
          textAnchor="middle"
          fill="currentColor"
        >
          App Core
        </text>
        <text
          x="155"
          y="110"
          fontSize="9"
          textAnchor="middle"
          fill="currentColor"
          opacity="0.6"
        >
          (Type-Safe)
        </text>
      </g>

      {/* Arrows showing validated flow */}
      <path
        d="M 75 65 L 90 65"
        stroke="currentColor"
        strokeWidth="2"
        markerEnd="url(#arrow-boundary)"
      />
      <path
        d="M 110 100 L 120 100"
        stroke={accentColor || "var(--ifm-color-primary)"}
        strokeWidth="2"
        markerEnd="url(#arrow-safe)"
      />

      <defs>
        <marker
          id="arrow-boundary"
          markerWidth="8"
          markerHeight="8"
          refX="7"
          refY="3"
          orient="auto"
        >
          <polygon points="0 0, 8 3, 0 6" fill="currentColor" />
        </marker>
        <marker
          id="arrow-safe"
          markerWidth="8"
          markerHeight="8"
          refX="7"
          refY="3"
          orient="auto"
        >
          <polygon
            points="0 0, 8 3, 0 6"
            fill={accentColor || "var(--ifm-color-primary)"}
          />
        </marker>
      </defs>
    </svg>
  );
}
