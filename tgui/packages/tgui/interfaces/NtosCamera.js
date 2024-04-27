import { Button, Flex, Stack, Slider, Box, Modal } from '../components';
import { useBackend } from '../backend';
import { NtosWindow } from '../layouts';

export const NtosCamera = (props, context) => {
  const { act, data } = useBackend(context);
  const { space, picture, error_msg } = data;
  const { picture_id, picture_width, picture_height } = picture;
  return (
    <NtosWindow width={Math.max(picture_width, 388)} height={70 + (picture_height ? Math.max(picture_height, 292) : 0)}>
      <Flex>
        {picture && <Flex.Item />}
        <Flex.Item>{(picture && <SaveOrDiscard />) || <SizeSettings />}</Flex.Item>
      </Flex>
      {error && (
        <Modal>
          <Flex direction="collumn" textAlign="center" width="picture_width">
            <Flex.Item>
              <h1 style={{ color: '#FF2222' }}>
                <b>ERROR!</b>
              </h1>
              {error_msg}
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
    </NtosWindow>
  );
};

const SizeSettings = (props, context) => {
  const { act, data } = useBackend(context);
  const { control_data, min_max_data } = data;
  const { cur_width, cur_height } = control_data;
  const { max_width, max_height, min_width, min_height } = min_max_data;
  return (
    <Stack>
      <Stack.Item>
        Width:
        <Slider
          minValue={min_width}
          maxValue={max_width}
          value={cur_width}
          onChange={(value) => {
            act('setWidth', {
              newWidth: value,
            });
          }}
        />
      </Stack.Item>
      <Stack.Item>
        Height:
        <Slider
          minValue={min_height}
          maxValue={max_height}
          value={cur_height}
          onChange={(value) => {
            act('setHeight', {
              newHeight: value,
            });
          }}
        />
      </Stack.Item>
    </Stack>
  );
};

const SaveOrDiscard = (props, context) => {
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
