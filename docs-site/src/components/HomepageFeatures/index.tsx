import type { ReactNode } from "react";
import clsx from "clsx";
import Heading from "@theme/Heading";
import styles from "./styles.module.css";
import { ValidationGateSVG } from "../ValidationGateSVG";
import { BoundaryGuardSVG } from "../BoundaryGuardSVG";
import { ZeroCostWrapperSVG } from "../ZeroCostWrapperSVG";

type FeatureItem = {
  title: string;
  Svg: React.ComponentType<React.ComponentProps<"svg">>;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: "Code-First Schemas",
    Svg: ValidationGateSVG,
    description: (
      <>
        Define expressive data contracts using pure Dart. No annotations, no{" "}
        <code>build_runner</code>. One schema to rule them all: from API
        boundaries to UI forms.
      </>
    ),
  },
  {
    title: "Defensive Runtime Safety",
    Svg: BoundaryGuardSVG,
    description: (
      <>
        Stop <code>TypeError</code> before they reach your business logic. Zema
        validates raw JSON at the edge, ensuring your models always operate on
        sanitized, type-safe data.
      </>
    ),
  },
  {
    title: "Zero-Cost & Zero Lock-In",
    Svg: ZeroCostWrapperSVG,
    description: (
      <>
        Leverage <strong>Extension Types</strong> for maximum performance.
        Integrate seamlessly with Freezed or existing classes. Secure your stack
        without the rewrite.
      </>
    ),
  },
];

function Feature({ title, Svg, description }: FeatureItem) {
  return (
    <div className={clsx("col col--4")}>
      <div className="text--center">
        <Svg className={styles.featureSvg} role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
