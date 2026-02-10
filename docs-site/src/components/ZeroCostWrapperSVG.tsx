import React from "react";

export function ZeroCostWrapperSVG({ className = "", accentColor }) {
  return (
    <svg
      viewBox="0 0 200 200"
      width="100%"
      height="auto"
      preserveAspectRatio="xMidYMid meet"
      className={className}
      role="img"
      aria-labelledby="zero-cost-title"
    >
      <title id="zero-cost-title">
        Extension Type as zero-cost abstraction over raw data
      </title>

      {/* Memory block: Raw Data */}
      <rect
        x="60"
        y="70"
        width="80"
        height="60"
        fill="currentColor"
        fillOpacity="0.05"
        stroke="currentColor"
        strokeWidth="2"
        strokeDasharray="4 4"
      />
      <text
        x="100"
        y="105"
        fontSize="12"
        textAnchor="middle"
        fill="currentColor"
      >
        Raw Data
      </text>

      {/* Thin type-safety membrane */}
      <rect
        x="55"
        y="65"
        width="90"
        height="70"
        fill="none"
        stroke={accentColor || "var(--ifm-color-primary)"}
        strokeWidth="2.5"
        rx="6"
      />

      {/* Label: Extension Type */}
      <text
        x="100"
        y="152"
        fontSize="11"
        fontWeight="600"
        textAnchor="middle"
        fill={accentColor || "var(--ifm-color-primary)"}
      >
        Extension Type
      </text>

      {/* Annotation: Zero allocation */}
      <text
        x="100"
        y="50"
        fontSize="9"
        textAnchor="middle"
        fill="currentColor"
        opacity="0.7"
      >
        Zero Heap Allocation
      </text>
      <path
        d="M 80 55 L 70 65 M 120 55 L 130 65"
        stroke="currentColor"
        strokeWidth="1.5"
        opacity="0.5"
      />
    </svg>
  );
}
