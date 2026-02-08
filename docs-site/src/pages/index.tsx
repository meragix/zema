import type { ReactNode } from "react";
import clsx from "clsx";
import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import HomepageFeatures from "@site/src/components/HomepageFeatures";
import Heading from "@theme/Heading";

import styles from "./index.module.css";

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx("hero hero--primary", styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/getting-started/installation"
          >
            Get Started - 5min ⏱️
          </Link>
        </div>

        <div className={styles.heroCode}>
          <pre>
            <code className="language-dart">
              {`
final userSchema = z.object({
  'id': z.integer(),
  'email': z.string().email(),
  'name': z.string().min(2),
});

// Validate API response
final user = await dio.get('/users/123')
  .then((res) => res.parseData(userSchema));

// Type-safe & validated ✨
print(user.name);
`}
            </code>
          </pre>
        </div>
      </div>
    </header>
  );
}

export default function Home(): ReactNode {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout
      title={`${siteConfig.title} - Schema-first validation for Dart`}
      description="Schema-first validation library for Dart & Flutter. Validate API responses, forms, and more."
    >
      <HomepageHeader />
      <main>
        <HomepageFeatures />

        <section className={styles.ecosystem}>
          <div className="container">
            <Heading as="h2">Complete Ecosystem</Heading>
            <div className="row">
              <div className="col col--4">
                <h3>🌐 zema_http</h3>
                <p>
                  Validate HTTP responses from any client (Dio, http, Chopper)
                </p>
              </div>
              <div className="col col--4">
                <h3>📝 zema_form</h3>
                <p>Type-safe form validation with cross-field rules</p>
              </div>
              <div className="col col--4">
                <h3>💾 zema_hive</h3>
                <p>Validated local storage without TypeAdapters</p>
              </div>
            </div>
            <div className="row" style={{ marginTop: "2rem" }}>
              <div className="col col--4">
                <h3>⚙️ zema_shared_preferences</h3>
                <p>Type-safe reactive settings</p>
              </div>
              <div className="col col--4">
                <h3>🔥 zema_firestore</h3>
                <p>Runtime validation for Firestore documents</p>
              </div>
              <div className="col col--4">
                <h3>🎣 zema_riverpod</h3>
                <p>Validated state management</p>
              </div>
            </div>
          </div>
        </section>

        {/* CTA */}
        <section className={styles.cta}>
          <div className="container">
            <Heading as="h2">Ready to Get Started?</Heading>
            <div className={styles.buttons}>
              <Link
                className="button button--primary button--lg"
                to="/docs/getting-started/installation"
              >
                Read the Docs
              </Link>
              <Link
                className="button button--secondary button--lg"
                to="https://github.com/meragix/zema"
              >
                View on GitHub
              </Link>
            </div>
          </div>
        </section>
      </main>
    </Layout>
  );
}
