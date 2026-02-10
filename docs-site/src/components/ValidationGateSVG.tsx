import React from "react";

export function ValidationGateSVG({ className = "", accentColor }) {
  const primary = accentColor || "var(--ifm-color-primary)";

  return (
    <svg
      viewBox="0 0 200 200"
      width="100%"
      height="auto"
      preserveAspectRatio="xMidYMid meet"
      className={className}
      role="img"
      aria-labelledby="validation-gate-title"
    >
      <title id="validation-gate-title">
        Schema validation pipeline transforming raw JSON to typed data
      </title>

      {/* Input: Raw JSON */}
      <rect
        x="20"
        y="85"
        width="40"
        height="30"
        rx="4"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
      />
      <text
        x="40"
        y="100"
        fontSize="10"
        textAnchor="middle"
        dominantBaseline="middle"
        fill="currentColor"
      >
        JSON
      </text>

      {/* Arrow in */}
      <path
        d="M 60 100 L 75 100"
        stroke="currentColor"
        strokeWidth="2"
        markerEnd="url(#arrowhead)"
      />

      {/* Central Hexagon */}
      <path
        d="M 100 70 L 120 85 L 120 115 L 100 130 L 80 115 L 80 85 Z"
        fill="none"
        stroke={primary}
        strokeWidth="2.5"
      />
      <text
        x="100"
        y="100"
        fontSize="8"
        fontWeight="600"
        textAnchor="middle"
        dominantBaseline="middle"
        fill={primary}
      >
        SCHEMA
      </text>

      {/* Arrow out */}
      <path
        d="M 120 100 L 135 100"
        stroke="currentColor"
        strokeWidth="2"
        markerEnd="url(#arrowhead)"
      />

      {/* Output: Typed object */}
      <rect
        x="135"
        y="85"
        width="45"
        height="30"
        rx="4"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
      />
      <text
        x="157.5"
        y="100"
        fontSize="10"
        textAnchor="middle"
        dominantBaseline="middle"
        fill="currentColor"
      >
        TYPED
      </text>

      {/* Success indicator */}
      <circle
        cx="157.5"
        cy="65"
        r="8"
        fill={primary}
        opacity="0.2"
      />
      <path
        d="M 154 65 L 156.5 67.5 L 161 63"
        fill="none"
        stroke={primary}
        strokeWidth="2"
        strokeLinecap="round"
      />

      {/* Arrow marker */}
      <defs>
        <marker
          id="arrowhead"
          markerWidth="10"
          markerHeight="10"
          refX="9"
          refY="3"
          orient="auto"
        >
          <polygon points="0 0, 10 3, 0 6" fill="currentColor" />
        </marker>
      </defs>
    </svg>
  );
}
