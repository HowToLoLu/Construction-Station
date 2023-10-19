import { useBackend } from '../backend';
import { Box, Button, Divider, LabeledList, Section, Flex, Input, Stack, Dropdown } from '../components';
import { Window } from '../layouts';

export const LibraryVisitorConsole = (props, context) => {
  const { act, data } = useBackend(context);
  // Extract `health` and `color` variables from the `data` object.
  const {
    search_data,
    categories,
    search_results,
    db_error,
  } = data;
  return (

    <Window>
      <Window.Content scrollable>
        <Box fontSize={2} align="center">
          Catalogue Search Menu
        </Box>
        <Stack vertical fill>
          <Divider />
          <LibraryConsoleSearch
            search_data={search_data}
            categories={categories}
            />
        </Stack>
      </Window.Content>
    </Window>
  );
};
const LibraryConsoleSearch = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    title,
    author,
    category,
  } = props.search_data;
  const categories = props.categories;
  return (
    <Flex.Item grow={1} position="sticky">
      <Section title="Search">
        <Flex direction="column" align="right">
          <Flex.Item>
            <Box right="">
              {'Title: '}
            </Box>
            <Input
              position="relative"
              left="50px"
              align="right"
              value={title}
              onChange={(e, value) => act('s_update', { 'book': title })}
            />
          </Flex.Item>
          <Flex.Item>
            {'Author: '}
            <Input
              position="relative"
              left="50px"
              align="right"
              value={author}
              onChange={(e, value) => act('s_update', { 'author': author })}
            />
          </Flex.Item>
          <Flex.Item>
            {'Category: '}
            <Dropdown
              selected={category}
              options={categories}
              displayText="Select"
              onSelected={(e, value) => act('s_update', { 'author': category })}
            />
          </Flex.Item>
          <Flex.Item>
            <Button
              content="Search"
              onClick={() => act('book_search')}
            />
          </Flex.Item>
        </Flex>
      </Section>
    </Flex.Item>
  );
};
