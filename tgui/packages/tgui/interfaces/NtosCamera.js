import { Button, Flex, Stack, Slider, Box, Modal, Divider } from '../components';
import { useBackend } from '../backend';
import { NtosWindow } from '../layouts';

export const NtosCamera = (props, context) => {
  const { act, data } = useBackend(context);
  const { error_msg, picture_width, picture_height, picture_id } = data;
  return (
    <NtosWindow width={Math.max(picture_width, 475)} height={100 + (picture_height ? Math.max(picture_height, 292) : 0)}>
      <NtosWindow.Content>
        <Flex direction="collumn" textAlign="center">
          <Flex.Item grow={1}>{(picture_id && <SaveOrDiscard />) || <SizeSettings />}</Flex.Item>
          {picture_id ? (
            <Flex.Item>
              <Box mt={1} width={`${picture_width}px`} height={`${picture_height}px`} as="img" src={picture_id} />
            </Flex.Item>
          ) : (
            ''
          )}
        </Flex>
        {error_msg && (
          <Modal>
            <Flex wrap="wrap" direction="collumn" textAlign="center" width={95}>
              <Flex.Item grow={1} max_width={95}>
                <h1 style={{ color: '#FF2222' }}>
                  <b>ERROR!</b>
                </h1>
                {/* {error_msg}*/}
              </Flex.Item>
              <Flex.Item>
                <Button
                  onClick={() => {
                    act('dismissError');
                  }}>
                  Dismiss
                </Button>
              </Flex.Item>
            </Flex>
          </Modal>
        )}
      </NtosWindow.Content>
    </NtosWindow>
  );
};

const SizeSettings = (props, context) => {
  const { act, data } = useBackend(context);
  const { control_data, min_max_data, space } = data;
  const { cur_width, cur_height } = control_data;
  const { max_width, max_height, min_width, min_height } = min_max_data;
  return (
    <Stack direction="row" textAlign="center" align="end">
      <Stack.Item grow={1}>
        <Stack justify="space" textAlign="center" align="end">
          <Stack.Item grow={1}>
            <Flex>
              <Flex.Item>Width: </Flex.Item>
              <Flex.Item grow={1}>
                <Slider
                  minWidth="50px"
                  stepPixelSize={40}
                  minValue={min_width}
                  maxValue={max_width}
                  value={cur_width}
                  onChange={(e, value) => {
                    act('setWidth', {
                      newWidth: value,
                    });
                  }}
                />
              </Flex.Item>
            </Flex>
          </Stack.Item>
          <Stack.Item grow={1}>
            <Flex>
              <Flex.Item>Height: </Flex.Item>
              <Flex.Item grow={1}>
                <Slider
                  minWidth="50px"
                  stepPixelSize={40}
                  minValue={min_height}
                  maxValue={max_height}
                  value={cur_height}
                  onChange={(e, value) => {
                    act('setHeight', {
                      newHeight: value,
                    });
                  }}
                />
              </Flex.Item>
            </Flex>
          </Stack.Item>
          <Stack.Item />
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <Flex>
          <Flex.Item>
            <Divider vertical={1} />
          </Flex.Item>
          <Flex.Item>Space Left: {space} GQ</Flex.Item>
        </Flex>
      </Stack.Item>
    </Stack>
  );
};

const SaveOrDiscard = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Stack>
      <Stack.Item>
        <Button
          onClick={() => {
            act('discardPicture');
          }}>
          Discard
        </Button>
      </Stack.Item>
      <Stack.Item>
        <Button
          onClick={() => {
            act('savePicture');
          }}>
          Save
        </Button>
      </Stack.Item>
    </Stack>
  );
};
