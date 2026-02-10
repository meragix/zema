import React, { JSX, useMemo } from "react";
import { useColorMode } from "@docusaurus/theme-common";
import styles from "./styles.module.css";

interface ZemaPlaygroundProps {
  /** GitHub Gist ID (ex: "a1b2c3d4e5f6") */
  gistId?: string;
  /** Titre affiché dans la barre (optionnel) */
  title?: string;
  /** Hauteur custom en pixels (défaut: 500) */
  height?: number;
  /** Ratio de split editor/console (défaut: 60) */
  split?: number | false;
  /** Active l'exécution auto au chargement (défaut: true) */
  autoRun?: boolean;
}

export default function ZemaPlayground({
  gistId,
  title = "Zema Playground",
  height = 500,
  split = 60,
  autoRun = false,
}: ZemaPlaygroundProps): JSX.Element {
  const { colorMode } = useColorMode();

  // Construction de l'URL DartPad avec tous les paramètres
  const iframeUrl = useMemo(() => {
    if (!gistId) return null;

    const params = new URLSearchParams({
      id: gistId,
      theme: colorMode,
      run: autoRun.toString(),
      ...(split !== false && { split: split.toString() }),
    });

    return `https://dartpad.dev/embed-dart.html?${params.toString()}`;
  }, [gistId, colorMode, autoRun, split]);

  // URL du Gist GitHub pour le lien externe
  const gistUrl = useMemo(
    () => (gistId ? `https://gist.github.com/${gistId}` : null),
    [gistId],
  );

  // URL DartPad standalone (sans embed)
  const dartpadUrl = useMemo(() => {
    if (!gistId) return null;
    return `https://dartpad.dev/?id=${gistId}`;
  }, [gistId]);

  // Fallback si gistId manquant
  if (!gistId) {
    return (
      <div className={styles.playgroundContainer} style={{ height }}>
        <div className={styles.titleBar}>
          <div className={styles.macButtons}>
            <span className={styles.macButtonRed} />
            <span className={styles.macButtonYellow} />
            <span className={styles.macButtonGreen} />
          </div>
          <span className={styles.title}>{title}</span>
        </div>
        <div className={styles.errorFallback}>
          <svg
            width="48"
            height="48"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
          >
            <circle cx="12" cy="12" r="10" />
            <line x1="12" y1="8" x2="12" y2="12" />
            <line x1="12" y1="16" x2="12.01" y2="16" />
          </svg>
          <p className={styles.errorText}>
            No Gist ID provided. Please specify a <code>gistId</code> prop.
          </p>

          <a
            href="https://dartpad.dev"
            target="_blank"
            rel="noopener noreferrer"
            className={styles.errorLink}
          >
            Open DartPad manually →
          </a>
        </div>
      </div>
    );
  }

  return (
    <div className={styles.playgroundContainer} style={{ height }}>
      {/* Barre de titre style macOS */}
      <div className={styles.titleBar}>
        <div className={styles.macButtons}>
          <span className={styles.macButtonRed} />
          <span className={styles.macButtonYellow} />
          <span className={styles.macButtonGreen} />
        </div>

        <a
          href={gistUrl}
          target="_blank"
          rel="noopener noreferrer"
          className={styles.title}
          title="View Gist on GitHub"
        >
          {title}
        </a>
      </div>

      {/* IFrame DartPad */}
      <iframe
        src={iframeUrl}
        className={styles.dartpadFrame}
        title={title}
        loading="lazy"
        allow="clipboard-write"
        sandbox="allow-scripts allow-same-origin allow-popups allow-forms"
      />

      {/* Footer avec bouton "Open in DartPad" */}
      <div className={styles.playgroundFooter}>
        <a
          href={dartpadUrl}
          target="_blank"
          rel="noopener noreferrer"
          className={styles.fullscreenButton}
          title="Open in DartPad (full screen)"
        >
          <svg
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7" />
          </svg>
          <span>Open in DartPad</span>
        </a>
      </div>
    </div>
  );
}
