import { defineChangelogConfig, defineMarkdownConfig, DocPageData } from '@cparra/apexdocs';
import * as fs from 'node:fs';

function loadFileAsync(filePath: string): Promise<string> {
  return new Promise((resolve, reject) => {
    fs.readFile(filePath, 'utf8', (err, data) => {
      if (err) {
        reject(err);
      } else {
        resolve(data);
      }
    });
  });
}

const TEMPLATE_DIR = './apexdocs/templates';

function readTemplate(name: string): string {
  return fs.readFileSync(`${TEMPLATE_DIR}/${name}.hbs`, 'utf8').trim();
}

// Custom templates receive no translations, so the templates use literal labels. Each file in
// partials/ is registered as an inline partial named after the file, and the class, interface and
// enum templates as classTemplate, interfaceTemplate and enumTemplate. These names replace ApexDocs'
// own partials of the same name, including where inner classes, interfaces and enums are rendered.
// customObject.hbs renders custom objects and custom metadata types.
const PARTIALS: Record<string, string> = {
  ...Object.fromEntries(
    fs
      .readdirSync(`${TEMPLATE_DIR}/partials`)
      .filter((file) => file.endsWith('.hbs'))
      .map((file) => [file.replace(/\.hbs$/, ''), readTemplate(`partials/${file.replace(/\.hbs$/, '')}`)]),
  ),
  classTemplate: readTemplate('class'),
  interfaceTemplate: readTemplate('interface'),
  enumTemplate: readTemplate('enum'),
};

function withPartials(template: string): string {
  const inlinePartials = Object.entries(PARTIALS)
    .map(([name, partial]) => `{{#*inline "${name}"}}\n${partial}\n{{/inline}}`)
    .join('\n');
  return `${inlinePartials}\n${template}`;
}

function writeFileAsync(filePath: string, data: string): Promise<void> {
  return new Promise((resolve, reject) => {
    fs.writeFile(filePath, data, (err) => {
      if (err) {
        reject(err);
      } else {
        resolve();
      }
    });
  });
}

export default {
  changelog: defineChangelogConfig({
    previousVersionDir: 'previous',
    currentVersionDir: 'force-app/src',
    scope: ['global', 'public', 'protected', 'private', 'namespaceaccessible'],
    transformChangeLogPage: () => {
      return {
        frontmatter: {
          title: 'Changelog',
        },
      };
    },
  }),
  markdown: defineMarkdownConfig({
    sourceDir: 'force-app/src',
    includeMetadata: false,
    scope: ['global', 'public', 'protected'],
    sortAlphabetically: true,
    transformReference: (reference) => {
      return {
        // remove the trailing .md
        referencePath: reference.referencePath.replace(/\.md$/, ''),
      };
    },
    transformReferenceGuide: async () => {
      const frontMatter = await loadFileAsync('./docs/index-frontmatter.md');
      return {
        frontmatter: frontMatter,
      };
    },
    // Framework internals that code using the framework never references
    exclude: ['**/executor/**', '**/TW_ActionRegistry.cls'],
    excludeTags: ['internal'],
    templates: {
      class: withPartials(PARTIALS.classTemplate),
      interface: withPartials(PARTIALS.interfaceTemplate),
      enum: withPartials(PARTIALS.enumTemplate),
      customObject: withPartials(readTemplate('customObject')),
    },
    transformDocs: async (docs) => {
      const apexOnlyDocs = docs.filter((doc) => doc.type !== 'customobject');
      const objectOnlyDocs = docs.filter((doc) => doc.type === 'customobject');

      // Update sidebar
      const sidebar = [
        {
          text: "Getting Started",
          link: "/getting-started.md"
        },
        {
          text: 'API Reference',
          items: Array.from(extractGroups(apexOnlyDocs)).map(([groupName, groupDocs]) => ({
            text: groupName,
            items: groupDocs.map(toSidebarLink),
          })),
        },
        {
          text: 'Object Reference',
          items: objectOnlyDocs.map(toSidebarLink),
        },
      ];
      await writeFileAsync('./docs/.vitepress/sidebar.json', JSON.stringify(sidebar, null, 2));

      return docs;
    },
    transformDocPage: async (docPage) => {
      return {
        ...docPage,
        frontmatter: {
          title: docPage.source.name,
        },
      };
    },
  }),
};

function toSidebarLink(doc: DocPageData) {
  return {
    text: doc.source.name,
    link: doc.outputDocPath,
  };
}

function extractGroups(docs: DocPageData[]) {
  const groups = new Map<string, DocPageData[]>();
  for (const doc of docs) {
    if (!doc.group) {
      continue;
    }

    const groupDocs = groups.get(doc.group) ?? [];
    groupDocs.push(doc);
    groups.set(doc.group, groupDocs);
  }

  return groups
}