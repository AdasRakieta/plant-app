import base64
import io
import tempfile
import unittest
from unittest.mock import patch
from PIL import Image
import shared_atlas as atlas

class AtlasTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.override = patch.object(atlas, 'DB', self.temp.name + '/atlas.db')
        self.override.start()
        self.body = {'name': 'Test plant', 'requirements': 'Observations pending verification.', 'source': 'Own observations', 'shareConsent': True}

    def tearDown(self):
        self.override.stop()
        self.temp.cleanup()

    def test_persists_across_connections_and_retry_is_idempotent(self):
        first = atlas.publish(self.body)['entry']
        self.assertEqual(atlas.publish(self.body)['entry'], first)
        self.assertEqual(atlas.entries()['entries'], [first])
        self.assertEqual(first['status'], 'community_unverified')

    def test_conflict_cannot_overwrite(self):
        atlas.publish(self.body)
        with self.assertRaises(ValueError):
            atlas.publish(dict(self.body, name='TEST PLANT', requirements='Other advice unverified.'))
        self.assertEqual(atlas.entries()['entries'][0]['requirements'], self.body['requirements'])

    def test_consent_and_invalid_images(self):
        with self.assertRaises(ValueError):
            atlas.publish(dict(self.body, shareConsent=False))
        with self.assertRaises(ValueError):
            atlas.publish(dict(self.body, image='not an image'))
        self.assertEqual(atlas.entries()['entries'], [])

    def test_image_is_small_reencoded_thumbnail(self):
        buf = io.BytesIO()
        Image.new('RGB', (800, 600)).save(buf, format='JPEG')
        result = atlas.publish(dict(self.body, image=base64.b64encode(buf.getvalue()).decode()))['entry']
        image = Image.open(io.BytesIO(base64.b64decode(result['image'])))
        self.assertEqual(image.size, (320, 240))
        self.assertFalse(image.getexif())

if __name__ == '__main__':
    unittest.main()
