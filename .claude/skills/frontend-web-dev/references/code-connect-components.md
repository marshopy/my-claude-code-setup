# Design System Components Reference

## Button

`@/components/uiv2/button`

| Prop | Type | Default |
|------|------|---------|
| colorVariant | `'primary'` \| `'secondary'` \| `'tertiary'` \| `'warning'` \| `'orange'` | `'primary'` |
| size | `'sm'` \| `'md'` \| `'lg'` | `'md'` |
| startContent | `ReactNode` | - |
| endContent | `ReactNode` | - |
| isDisabled | `boolean` | `false` |

```tsx
import { Button } from '@/components/uiv2/button';
import { Icon } from '@/components/icons/Icon';

<Button colorVariant="primary">Save</Button>
<Button colorVariant="secondary" size="sm">Cancel</Button>
<Button
  colorVariant="warning"
  startContent={<Icon name="bin" size={20} color="currentColor" />}
>
  Delete
</Button>
<Button endContent={<Icon name="down" size={16} color="currentColor" />}>Dropdown</Button>
```

---

## Chip

`@/components/ui/chip`

| Prop | Type | Default |
|------|------|---------|
| color | `'blue'` \| `'grey'` \| `'green'` \| `'purple'` \| `'yellow'` \| `'red'` \| `'multi'` | `'grey'` |
| size | `'sm'` \| `'md'` \| `'lg'` | `'md'` |
| startContent | `ReactNode` | - |
| onClose | `() => void` | - |
| isDisabled | `boolean` | `false` |

```tsx
import { Chip } from '@/components/ui/chip';

<Chip color="blue">Active</Chip>
<Chip color="green" size="sm">Success</Chip>
<Chip color="red" onClose={() => handleRemove()}>Removable</Chip>
```

---

## Checkbox

`@/components/ui/checkbox`

| Prop | Type | Default |
|------|------|---------|
| isSelected | `boolean` | `false` |
| isIndeterminate | `boolean` | `false` |
| isInvalid | `boolean` | `false` |
| isDisabled | `boolean` | `false` |
| children | `ReactNode` | - |

```tsx
import { Checkbox } from '@/components/ui/checkbox';

<Checkbox isSelected={checked} onValueChange={setChecked}>
  Accept terms
</Checkbox>
<Checkbox isIndeterminate>Partial selection</Checkbox>
<Checkbox isInvalid>Required field</Checkbox>
```

---

## Radio

`@/components/ui/radio`

Exports: `Radio`, `RadioGroup`

### Radio Props

| Prop | Type | Default |
|------|------|---------|
| value | `string` | - |
| description | `ReactNode` | - |
| isDisabled | `boolean` | `false` |
| isInvalid | `boolean` | `false` |
| children | `ReactNode` | - |

### RadioGroup Props

| Prop | Type | Default |
|------|------|---------|
| value | `string` | - |
| defaultValue | `string` | - |
| onValueChange | `(value: string) => void` | - |
| orientation | `'vertical'` \| `'horizontal'` | `'vertical'` |
| isDisabled | `boolean` | `false` |
| isInvalid | `boolean` | `false` |

```tsx
import { Radio, RadioGroup } from '@/components/ui/radio';

<RadioGroup aria-label="Quality" value={quality} onValueChange={setQuality}>
  <Radio value="low">Low</Radio>
  <Radio value="high" description="Best results">
    High
  </Radio>
</RadioGroup>
```

---

## Container

`@/components/ui/container`

| Prop | Type | Default |
|------|------|---------|
| type | `'default'` \| `'hover'` \| `'light'` \| `'no shadow'` \| `'row header'` \| `'inner'` | `'default'` |

```tsx
import { Container } from '@/components/ui/container';

<Container type="default">Content</Container>
<Container type="light" className="p-4">Light container</Container>
<Container type="inner">Nested content</Container>
```

---

## Divider

`@/components/ui/divider`

| Prop | Type | Default |
|------|------|---------|
| orientation | `'horizontal'` \| `'vertical'` | `'horizontal'` |
| thickness | `'1px'` \| `'2px'` \| `'3px'` | `'1px'` |

```tsx
import { Divider } from '@/components/ui/divider';

<Divider />
<Divider thickness="2px" />
<Divider orientation="vertical" className="h-6" />
```

---

## Dropdown

`@/components/ui/dropdown`

Exports: `Dropdown`, `DropdownItem`, `ComboBox`, `ComboBoxItem`

### Dropdown (Select)

`Dropdown` wraps HeroUI `Select` with design-system defaults.

| Prop | Type | Default |
|------|------|---------|
| styleVariant | `'outline'` \| `'solid'` | `'outline'` |

```tsx
import { Dropdown, DropdownItem } from '@/components/ui/dropdown';

<Dropdown
  aria-label="Status"
  label="Status"
  placeholder="Select…"
  items={[
    { key: 'open', name: 'Open' },
    { key: 'closed', name: 'Closed' },
  ]}
  selectedKeys={new Set(['open'])}
  onSelectionChange={(keys) => {
    if (keys === 'all') return;
    const selected = Array.from(keys)[0];
    // ...
  }}
>
  {(item) => <DropdownItem key={item.key}>{item.name}</DropdownItem>}
</Dropdown>
```

### ComboBox (Autocomplete)

`ComboBox` wraps HeroUI `Autocomplete` for typeahead / server-backed lists.

| Prop | Type | Default |
|------|------|---------|
| styleVariant | `'outline'` \| `'solid'` | `'outline'` |

```tsx
import { ComboBox, ComboBoxItem } from '@/components/ui/dropdown';

<ComboBox
  aria-label="Search"
  placeholder="Search…"
  items={items}
  inputValue={query}
  onInputChange={setQuery}
  onSelectionChange={(key) => {
    if (!key) return;
    // ...
  }}
  isLoading={isLoading}
  allowsCustomValue={false}
  menuTrigger="input"
>
  {(item) => <ComboBoxItem key={item.key}>{item.name}</ComboBoxItem>}
</ComboBox>
```

---

## Menu

`@/components/ui/menu`

Exports: `Menu`, `MenuTrigger`, `MenuContent`, `MenuItem`

### MenuItem Props

| Prop | Type |
|------|------|
| startIcon | `string` |
| isDisabled | `boolean` |

```tsx
import { Button } from '@/components/uiv2/button';
import { Menu, MenuTrigger, MenuContent, MenuItem } from '@/components/ui/menu';

<Menu>
  <MenuTrigger>
    <Button>Options</Button>
  </MenuTrigger>
  <MenuContent aria-label="Actions">
    <MenuItem startIcon="edit">Edit</MenuItem>
    <MenuItem startIcon="paste">Duplicate</MenuItem>
    <MenuItem startIcon="bin">Delete</MenuItem>
  </MenuContent>
</Menu>
```

---

## Modal

`@/components/ui/modal`

Exports: `Modal`, `ModalContent`, `ModalHeader`, `ModalBody`, `ModalFooter`, `ModalCloseButton`

```tsx
import { Button } from '@/components/uiv2/button';
import { Modal, ModalBody, ModalContent, ModalFooter, ModalHeader } from '@/components/ui/modal';

<Modal isOpen={isOpen} onOpenChange={(open) => !open && onClose()}>
  <ModalContent>
    <ModalHeader>Modal title</ModalHeader>
    <ModalBody>Content…</ModalBody>
    <ModalFooter>
      <Button colorVariant="secondary" onPress={onClose}>
        Cancel
      </Button>
      <Button colorVariant="primary" onPress={onConfirm}>
        Confirm
      </Button>
    </ModalFooter>
  </ModalContent>
</Modal>
```

---

## Search

`@/components/ui/search`

| Prop | Type | Default |
|------|------|---------|
| size | `'md'` \| `'lg'` | `'md'` |
| variant | `'outline'` \| `'solid'` | `'outline'` |
| placeholder | `string` | - |
| defaultValue | `string` | - |
| onClear | `() => void` | - |

```tsx
import { Search } from '@/components/ui/search';

<Search placeholder="Search..." onClear={() => setValue('')} />
<Search size="lg" variant="solid" defaultValue="query" />
```

---

## Slider

`@/components/ui/slider`

Exports: `Slider`, `SliderBar`, `SliderDot`, `SliderItemButton`

### Slider Props

| Prop | Type | Default |
|------|------|---------|
| label | `string` | - |
| minValue | `number` | - |
| maxValue | `number` | - |
| step | `number` | `1` |
| defaultValue | `number` \| `[number, number]` | - |
| marks | `{ value: number; label: string }[]` | - |
| variant | `'quick buttons'` \| `'labels only'` | - |

```tsx
import { Slider } from '@/components/ui/slider';

<Slider
  aria-label="Volume"
  label="Volume"
  minValue={0}
  maxValue={100}
  defaultValue={50}
  marks={[
    { value: 0, label: 'Low' },
    { value: 50, label: 'Medium' },
    { value: 100, label: 'High' },
  ]}
/>

// Range slider (dual knobs)
<Slider
  aria-label="Price range"
  minValue={0}
  maxValue={1000}
  defaultValue={[200, 800]}
/>
```

### SliderBar Props

| Prop | Type |
|------|------|
| variant | `'base'` \| `'progress'` |

### SliderItemButton

```tsx
import { SliderItemButton } from '@/components/ui/slider';

<SliderItemButton>Label</SliderItemButton>
```

---

## Table

`@/components/ui/table`

Exports: `Table`, `TableRow`, `TableColumnHeader`, `TableColumn` (type)

### Table Props

| Prop | Type |
|------|------|
| ariaLabel | `string` |
| data | `T[]` |
| columns | `TableColumn<T>[]` |
| getRowKey | `(row: T) => string \| number` |
| selectionMode | `'none'` \| `'multiple'` |
| selectedKeys | `Set<string \| number>` |
| onSelectionChange | `(keys: Set<string \| number>) => void` |
| pagination | `{ page: number; totalPages: number; onPageChange: (page: number) => void }` |

```tsx
import { Table, type TableColumn } from '@/components/ui/table';

type Row = { id: number; name: string; status: string };

const columns: TableColumn<Row>[] = [
  { key: 'name', label: 'Name', allowsSorting: true },
  { key: 'status', label: 'Status' },
];

<Table<Row>
  ariaLabel="Users"
  data={users}
  columns={columns}
  getRowKey={(row) => row.id}
  selectionMode="multiple"
  selectedKeys={selectedIds}
  onSelectionChange={setSelectedIds}
  pagination={{ page: 1, totalPages: 10, onPageChange: setPage }}
/>
```

### TableRow Props

| Prop | Type |
|------|------|
| type | `'1st row'` \| `'generic row'` \| `'header row'` \| `'pagination'` \| `'no data'` |

### TableColumnHeader Props

| Prop | Type |
|------|------|
| sort | `'unsorted'` \| `'ascending'` \| `'descending'` |

---

## Breadcrumbs

`@/components/ui/breadcrumb`

Exports: `Breadcrumbs`, `BreadcrumbItem`

### Breadcrumbs Props

| Prop | Type | Default |
|------|------|---------|
| showBackIcon | `boolean` | `false` |
| backHref | `string` | - |

### BreadcrumbItem Props

| Prop | Type |
|------|------|
| href | `string` (omit for current page) |

```tsx
import { Breadcrumbs, BreadcrumbItem } from '@/components/ui/breadcrumb';

<Breadcrumbs showBackIcon backHref="/dashboard">
  <BreadcrumbItem href="/dashboard">Dashboard</BreadcrumbItem>
  <BreadcrumbItem href="/settings">Settings</BreadcrumbItem>
  <BreadcrumbItem>Profile</BreadcrumbItem>
</Breadcrumbs>
```

---

## SidebarNavItem

`@/components/layout/sidebar/SidebarNavItem`

| Prop | Type |
|------|------|
| label | `string` |
| href | `string` |
| layout | `'row'` \| `'tile'` |
| icon | `ReactNode` |
| isActive | `boolean` |

```tsx
import { SidebarNavItem } from '@/components/layout/sidebar/SidebarNavItem';
import { Icon } from '@/components/icons/Icon';

<SidebarNavItem
  label="Home"
  href="/"
  layout="row"
  icon={<Icon name="home" size={28} color="currentColor" />}
  isActive={pathname === '/'}
/>
```

---

## CompactSidebarWithSections

`@/components/layout/sidebar`

```tsx
import { CompactSidebarWithSections } from '@/components/layout/sidebar';

<CompactSidebarWithSections />
```

---

## SwitcherMenuItem

`@/components/ui/switcher-menu-item`

| Prop | Type | Default |
|------|------|---------|
| label | `string` | - |
| visual | `{ type: 'avatar'; name: string }` | - |
| chipLabel | `string` | - |
| isSelected | `boolean` | `false` |
| showDrillDown | `boolean` | `false` |
| reserveDrillDownSpace | `boolean` | `false` |

```tsx
import { SwitcherMenuItem } from '@/components/ui/switcher-menu-item';

<SwitcherMenuItem
  label="Personal Workspace"
  visual={{ type: 'avatar', name: 'Alex' }}
  chipLabel="Personal"
  isSelected={isActive}
  showDrillDown
/>
```

---

## Finding Components

```bash
# List all Code Connect components
find apps/web/src/components -name "*.figma.tsx"
```

Create new components only when no existing component fits the use case.
