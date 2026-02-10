import type { ReactNode } from "react";
import clsx from "clsx";
import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import HomepageFeatures from "@site/src/components/HomepageFeatures";
import Heading from "@theme/Heading";
import CodeBlock from "@theme/CodeBlock";

import styles from "./index.module.css";
import ZemaPlayground from "../components/ZemaPlayground";
import HomepageMigration from "../components/HomepageMigration";
import { FlutterIcon, NetworkIcon, ServerIcon } from "../components/Logos";

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={styles.heroZema}>
      <div className={styles.heroZema__grid}>
        {/* Left: Content */}
        <div className={styles.heroZema__content}>
          <h1>
            Schema validation for{" "}
            <span className={styles.heroZema__gradient}>Dart</span>, minus the
            boilerplate
          </h1>

          <p>{siteConfig.tagline}</p>

          <div className={styles.heroZema__actions}>
            <Link
              className="button button--primary button--lg"
              to="/docs/getting-started/installation"
            >
              Get Started
            </Link>

            <Link
              className="button button--outline button--primary button--lg"
              to="/docs"
            >
              Learn more
            </Link>

            {/* <span className={styles.indexCtasGitHubButtonWrapper}>
              <iframe
                className={styles.indexCtasGitHubButton}
                src="https://ghbtns.com/github-btn.html?user=meragix&amp;repo=zema&amp;type=star&amp;count=true&amp;size=large"
                width={160}
                height={30}
                title="GitHub Stars"
              />
            </span> */}
          </div>
        </div>

        {/* Right: Code preview */}
        <div className={styles.heroZema__code}>
          <div className={styles.heroZema__codeHeader}>
            <span
              className={clsx(
                styles.heroZema__dot,
                styles["heroZema__dot--red"],
              )}
            />
            <span
              className={clsx(
                styles.heroZema__dot,
                styles["heroZema__dot--yellow"],
              )}
            />
            <span
              className={clsx(
                styles.heroZema__dot,
                styles["heroZema__dot--green"],
              )}
            />
          </div>

          <CodeBlock language="dart" showLineNumbers={false}>
            {`
// 1. Define your schema
final userSchema = z.object({
  'name': z.string().min(2),
  'email': z.string().email(),
  'age': z.int().positive().optional(),
});

// 2. Validate & type-safe access
final result = userSchema.parse(json);

if (result is ZemaSuccess) {
  print(result.data.name); // Autocompletion works here!
}`}
          </CodeBlock>
        </div>
      </div>
    </header>

    //     <header className={clsx("hero hero--primary", styles.heroBanner)}>
    //       <div className="container">
    //         <Heading as="h1" className="hero__title">
    //           {siteConfig.title}
    //         </Heading>
    //         <p className="hero__subtitle">{siteConfig.tagline}</p>
    //         <div className={styles.buttons}>
    //           <Link
    //             className="button button--secondary button--lg"
    //             to="/docs/getting-started/installation"
    //           >
    //             Get Started - 5min ⏱️
    //           </Link>
    //         </div>

    //         <div className={styles.heroCode}>
    //           <pre>
    //             <code className="language-dart">
    //               {`
    // // 1. Define your schema
    // final userSchema = z.object({
    //   'name': z.string().min(2),
    //   'email': z.string().email(),
    //   'age': z.number().int().positive().optional(),
    // });

    // // 2. Validate & Type-safe access
    // final result = userSchema.parse(json);

    // if (result is ZemaSuccess) {
    //   print(result.data.name); // Autocompletion works here!
    // }
    // `}
    //             </code>
    //           </pre>
    //         </div>
    //       </div>
    //     </header>
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
        <section className={styles.liveDemo}>
          <div className="container">
            <div className={styles.liveDemoHeader}>
              <h2>
                Try Zema <span className="text--primary">Live</span>
              </h2>
              <p>Experiment with schema validation directly in your browser</p>
            </div>

            <ZemaPlayground
              gistId="bc1a33c45c2e3ba672be5a3b4431a2da"
              title="Zema Schema Validation"
              height={600}
            />
          </div>
        </section>

        {/* Zero-Cost Section */}
        <section className="zemaZeroCost">
          <div className="container">
            <div className="zemaZeroCost__header">
              <h2>
                <span className="zemaZeroCost__highlight">Zero-Cost</span>{" "}
                Architecture
              </h2>
              <p>
                Zema leverages <strong>Dart 3.3+ Extension Types</strong> to
                provide type-safety without the performance penalty of
                traditional models.
              </p>
            </div>

            <div className="zemaZeroCost__grid">
              {/* Traditional */}
              <div className="zemaZeroCost__card">
                <h3>Standard POJOs / Freezed</h3>

                <ul className="zemaZeroCost__list">
                  <li>
                    <span className="zemaZeroCost__dot zemaZeroCost__dot--bad" />
                    <div>
                      <strong>Deep Cloning</strong>
                      <p>Every validation creates a full copy of your data.</p>
                    </div>
                  </li>

                  <li>
                    <span className="zemaZeroCost__dot zemaZeroCost__dot--bad" />
                    <div>
                      <strong>GC Pressure</strong>
                      <p>
                        Constant object allocations trigger the Garbage
                        Collector.
                      </p>
                    </div>
                  </li>

                  <li>
                    <span className="zemaZeroCost__dot zemaZeroCost__dot--bad" />
                    <div>
                      <strong>Boxed Types</strong>
                      <p>
                        Adds a wrapper layer between your app and the raw JSON.
                      </p>
                    </div>
                  </li>
                </ul>
              </div>

              {/* Zema */}
              <div className="zemaZeroCost__card zemaZeroCost__card--highlight">
                <div className="zemaZeroCost__glow" />

                <h3>The Zema Way</h3>

                <ul className="zemaZeroCost__list">
                  <li>
                    <span className="zemaZeroCost__dot zemaZeroCost__dot--good" />
                    <div>
                      <strong>In-Place Validation</strong>
                      <p>
                        We validate your raw Map directly. No cloning. No lag.
                      </p>
                    </div>
                  </li>

                  <li>
                    <span className="zemaZeroCost__dot zemaZeroCost__dot--good" />
                    <div>
                      <strong>Identity Preservation</strong>
                      <p>
                        <code>identical(rawData, zemaObject)</code> is always
                        true.
                      </p>
                    </div>
                  </li>

                  <li>
                    <span className="zemaZeroCost__dot zemaZeroCost__dot--good" />
                    <div>
                      <strong>Static Type Casting</strong>
                      <p>
                        Type safety is enforced at compile-time with zero
                        runtime cost.
                      </p>
                    </div>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </section>

        <HomepageFeatures />

        {/* Ecosystem Section */}
        <section id="ecosystem" className="zemaEcosystem">
          <div className="container">
            <div className="zemaEcosystem__header">
              <h2>Native Integration</h2>
              <p>
                Zema is pure Dart. It secures your data flow across the entire
                stack.
              </p>
            </div>

            <div className="zemaEcosystem__grid">
              <div className="zemaEcosystem__card">
                <div className="zemaEcosystem__icon">
                  <FlutterIcon />
                </div>
                <h3>Flutter Forms(Coming Soon)</h3>
                <p>
                  Bind schemas directly to your UI. Use <code>zema</code> to
                  drive reactive form validation with localized error messages.
                </p>
              </div>

              <div className="zemaEcosystem__card">
                <div className="zemaEcosystem__icon">
                  <NetworkIcon />
                </div>
                <h3>Type-Safe I/O(Coming Soon)</h3>
                <p>
                  Perfect for <strong>Dio</strong> or <strong>Http</strong>.
                  Validate incoming JSON at the edge before it touches your
                  business logic.
                </p>
              </div>

              <div className="zemaEcosystem__card">
                <div className="zemaEcosystem__icon">
                  <ServerIcon />
                </div>
                <h3>Server-Side Dart(Coming Soon)</h3>
                <p>
                  Run the same schemas in <strong>Dart Frog</strong> or{" "}
                  <strong>Shelf</strong>. Garantie 100% logic sharing between
                  client and server.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* Migration */}
        <HomepageMigration />

        {/* CTA */}
        <section className={styles.cta}>
          <div className="container">
            <Heading as="h2" className={styles.ctaTitle}>
              Ready to build <span>bulletproof</span> apps?
            </Heading>

            <p className={styles.ctaSubtitle}>
              Join the next generation of Dart developers using zero-cost
              validation. No build runner, no boilerplate, just pure type
              safety.
            </p>

            <div className={styles.ctaActions}>
              <Link
                className="button button--primary button--lg"
                to="/docs/getting-started/installation"
              >
                Get Started Now
              </Link>
              <Link className="button button--secondary button--lg" to="/docs">
                Explore the API
              </Link>
            </div>

            <div className={styles.ctaTerminal}>
              <CodeBlock language="bash">
                {`
dart pub add zema
`}
              </CodeBlock>
            </div>
          </div>
        </section>
      </main>
    </Layout>
  );
}
