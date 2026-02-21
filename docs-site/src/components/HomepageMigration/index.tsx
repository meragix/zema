import React, { ReactNode } from "react";
import Tabs from "@theme/Tabs";
import TabItem from "@theme/TabItem";
import CodeBlock from "@theme/CodeBlock";
import styles from "./styles.module.css";
import clsx from "clsx";

export default function HomepageMigration(): ReactNode {
  return (
    <section className={styles.migration}>
      <div className="container">
        <div className={styles.migrationHeader}>
          <h2>Cleaner Code</h2>
          <p>See the difference with real-world examples</p>
        </div>

        <Tabs
          defaultValue="without"
          values={[
            { label: "Without Zema", value: "without" },
            { label: "With Zema", value: "with" },
          ]}
        >
          <TabItem value="without">
            <div className={styles.migrationCodeCard}>
              <CodeBlock language="dart" showLineNumbers>
                {`
class User {
  final String name;
  final String email;
  final int age;

  User({required this.name, required this.email, required this.age});

  factory User.fromJson(Map<String, dynamic> json) {
    // 1. Verbose and repetitive manual validation
    if (json['name'] == null || (json['name'] as String).isEmpty) {
      throw Exception('Name is required');
    }
    
    // 2. Fragility of casts (Risk of TypeError at runtime)
    final email = json['email'] as String; 
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      throw Exception('Invalid email format');
    }

    final age = json['age'] as int;
    if (age < 18) {
      throw Exception('User must be an adult');
    }

    // 3. No overall vision: stops at the first error found
    return User(
      name: json['name'],
      email: email,
      age: age,
    );
  }
}
`}
              </CodeBlock>
            </div>
          </TabItem>

          <TabItem value="with">
            <div
              className={clsx(
                styles.migrationCodeCard,
                styles["migrationCodeCard--highlight"],
              )}
            >
              <CodeBlock language="dart" showLineNumbers>
                {`
final userSchema = z.object({
  'name': z.string().min(1),
  'email': z.string().email(),
  'age': z.int().min(18),
});

extension type User(Map<String, dynamic> _)  {
  String get name => _['name'];
  String get email => _['email'];
  String get age => _['age'];
}

void main() {
  final result = userSchema.safeParse(json);
  
  if (result is ZemaSuccess) {
    // 'user' is now typed and has autocompletion
    final user = result.data; 
    print(user.name); 
  }
}
`}
              </CodeBlock>
            </div>
          </TabItem>
        </Tabs>
      </div>
    </section>
  );
}
